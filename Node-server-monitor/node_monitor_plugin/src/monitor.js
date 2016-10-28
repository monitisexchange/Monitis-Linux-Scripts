var events = require('events')
  , sys = require('util')
  , http = require('http')
  , url = require('url')
  , utils = require('./util/utils');

// ****** Constants ******
var HOST_LISTEN = "127.0.0.1";
var PORT_LISTEN = 10010;
var MAX_VALUE = Number.MAX_VALUE;
var TOP_MAX = 3; // The maximum number of collected requests that spent most time for execution
var TOP_LIMIT = 1; // the monitor have to collect info when exceeding the number of specified seconds only
var STATUS_OK = 'OK';
var STATUS_NOK = 'NOK';
var STATUS_DOWN = 'DOWN';
var STATUS_IDLE = 'IDLE';
// ***********************

var monitors = [];

function createMon() {
	// monitored data structure
	var mon = {
		// options
		'collect_all' : false,
		// fixed part
		'server' : null,
		'listen' : "",
		'requests' : 0,
		'post_count' : 0,
		'exceptions' : 0,
		'get_count' : 0,
		'active' : 0,
		// Total
		'time' : 0,
		'avr_time' : 0,
		'min_time' : MAX_VALUE,
		'max_time' : 0,
		// Network latency
		'net_time' : 0,
		'avr_net_time' : 0,
		'min_net_time' : MAX_VALUE,
		'max_net_time' : 0,
		// Server responce time
		'resp_time' : 0,
		'avr_resp_time' : 0,
		'min_resp_time' : MAX_VALUE,
		'max_resp_time' : 0,
		// Read/Writes
		'bytes_read' : 0,
		'bytes_written' : 0,
		// Status codes
		'1xx' : 0,
		'2xx' : 0,
		'3xx' : 0,
		'4xx' : 0,
		'timeout' : 0,// status code 408
		'5xx' : 0,
		'timeS' : new Date().getTime(),
		'timeE' : new Date().getTime(),
		'status' : STATUS_IDLE,
		// flexible part
		'info' : {
			'add' : function(name, data, count) {
				if (!this[name]) {
					this[name] = {};
				}

				if (this[name][data]) {
					this[name][data] += count != undefined ? count : 1;
				} else {
					this[name][data] = count != undefined ? count : 1;
				}
			},
			'addSorted' : function(name, data, sort_key_value) {
				var value = sort_key_value / 1000;
				if (TOP_MAX <= 0 || TOP_LIMIT > value) {
					return;
				}
				if (!this[name]) {
					this[name] = [];
				}
				var t = {
					't' : value,
					'data' : data
				};
				this[name].push(t);
				if (this[name].length > 1) {
					this[name].sort(function(a, b) {
						return b['t'] - a['t'];
					})
				}
				if (this[name].length > TOP_MAX) {
					this[name].pop();
				}
			},
			'addAll' : function(info) {
				var self = this;
				var t = "";
				function isArray(obj) {
					return obj.constructor == Array;
				}
				JSON.stringify(info, function(key, value) {
					if (typeof (value) == 'object') {
						if (!isArray(value)) {
							t = key;
						} else {
							value.forEach(function(element, index, value) {
								self.addSorted(key, element['data'], element['t'])
							}, self);
							return;
						}
					} else if (typeof(value) != 'function' && t.length > 0) {
						self.add(t, key, value);
					}
					return value;
				});
			}
		}

	};
	return mon;
}

/**
 * Adds the given server to the monitor chain
 * 
 * @param server
 *            {Object}
 * @param options
 *            {Object} the options for given server monitor 
 *            {'collect_all': ('yes' | 'no'), 'top':{'max':<value>, 'limit':<value>}} 
 *            where top.max - the maximum number of collected requests that spent most time for execution 
 *            top.limit - the monitor have to collect info when exceeding the number of specified seconds only
 *            default - {'collect_all': 'no', 'top':{'max':3, 'limit':1}}
 * @returns {Object} mon_server structure if given server added to the monitor chain 
 * 					 null if server is already under monitoring
 */
function addToMonitors(server, options) {
	var collect_all = false;
	if ('object' == typeof options) {
		console.log("Registering Monitor: " + JSON.stringify(options));
		collect_all = (options['collect_all'] && options['collect_all'] == 'yes') ? true : false;
		if (options['top'] && options['top']['max'] != undefined) {
			TOP_MAX = Math.max(TOP_MAX, Math.max(options['top']['max'], 0));
		}
		if (options['top'] && options['top']['limit'] != undefined) {
			TOP_LIMIT = options['top']['limit'] <= 0 ? 0 : Math.max(TOP_LIMIT, options['top']['limit']);
		}
	} else {
		options = {}
	}

	if (server && options.active != "no" && (monitors.length == 0 || !monitors.some(function(element) {
		return element['server'] == server;
	}))) {
		var mon_server = createMon();
		var host = server.address()['address'] + ":" + server.address()['port'];
		mon_server['collect_all'] = collect_all;
		mon_server['server'] = server;
		mon_server['listen'] = server.address()['port'];// host;
		monitors.push(mon_server);
		console.log("Server " + host + " added to monitors chain");
		return mon_server;
	}
	console.warn("Monitor isn't activated ("+(options.active == "no"? "active = no":"couldn't add the same server")+")");
	return null;
}

/**
 * Removes given server from monitor chain
 * 
 * @param server
 */
function removeFromMonitor(server) {
	if (server && monitors.length > 0) {
		for ( var i = 0; i < monitors.length; i++) {
			var mon_server = monitors[i];
			if (mon_server['server'] == server) {
				console.warn("Server " + mon_server['listen'] + " stopped and removed from monitors chain");
				monitors.splice(i, 1);// remove monitored element
			}
		}
	}
}

function addExceptionToMonitor(server, callback) {
	var ret = false;
	if (server && monitors.length > 0) {
		for ( var i = 0; i < monitors.length; i++) {
			var mon_server = monitors[i];
			if (mon_server['server'] == server && mon_server.hasOwnProperty('exceptions')) {
				++mon_server['exceptions'];
				ret = true;
				break;
			}
		}
	}
	return (callback ? (callback(!ret)) : (ret));
}
exports.addExceptionToMonitor = addExceptionToMonitor;

function addResultsToMonitor(server, requests, post_count, get_count, net_duration, pure_duration, total_duration,
		bytes_read, bytes_written, status_code, info, userInfo, callback) {
	var ret = false;
	if (server && monitors.length > 0) {
		for ( var i = 0; i < monitors.length; i++) {
			var mon_server = monitors[i];
			if (mon_server['server'] == server) {
				mon_server['time'] += total_duration;
				mon_server['min_time'] = Math.min(total_duration, mon_server['min_time']);
				if (status_code != 408)// timeout shouldn't be calculated
					mon_server['max_time'] = Math.max(total_duration, mon_server['max_time']);
				mon_server['resp_time'] += pure_duration;
				mon_server['min_resp_time'] = Math.min(pure_duration, mon_server['min_resp_time']);
				if (status_code != 408)// timeout shouldn't be calculated
					mon_server['max_resp_time'] = Math.max(pure_duration, mon_server['max_resp_time']);
				mon_server['net_time'] += net_duration;
				mon_server['min_net_time'] = Math.min(net_duration, mon_server['min_net_time']);
				if (status_code != 408)// timeout shouldn't be calculated
					mon_server['max_net_time'] = Math.max(net_duration, mon_server['max_net_time']);
				mon_server['active'] += ((net_duration + pure_duration) / 1000);
				mon_server['requests'] += requests;
				mon_server['avr_time'] = mon_server['time'] / mon_server['requests'];
				mon_server['avr_resp_time'] = mon_server['resp_time'] / mon_server['requests'];
				mon_server['avr_net_time'] = mon_server['net_time'] / mon_server['requests'];
				mon_server['post_count'] += post_count;
				mon_server['get_count'] += get_count;
				mon_server['bytes_read'] += bytes_read;
				mon_server['bytes_written'] += bytes_written;
				mon_server['1xx'] += (status_code < 200 ? 1 : 0);
				mon_server['2xx'] += (status_code >= 200 && status_code < 300 ? 1 : 0);
				mon_server['3xx'] += (status_code >= 300 && status_code < 400 ? 1 : 0);
				mon_server['4xx'] += (status_code >= 400 && status_code < 500 ? 1 : 0);
				mon_server['5xx'] += (status_code >= 500 ? 1 : 0);
				mon_server['timeout'] += (status_code == 408 ? 1 : 0);// DEBUG
				mon_server['timeE'] = new Date().getTime();
				if (typeof(info) == 'Object') {
					mon_server['info'].addAll(info);
				}
				if (userInfo) {
					mon_server['info'].addSorted('top' + TOP_MAX, userInfo, total_duration);
				}
				ret = true;
				break;
			}
		}
	}
	return (callback ? (callback(!ret)) : (ret));
}

/**
 * Composes all monitored servers data in following form <server1 data string> <server2 data string> ......
 * 
 * @param clean
 *            (optional) if given, it is forcing to clear all accumulated data after composing a summarized result
 *            string
 * 
 * @returns {String}
 */
function getMonitorAllResults(clean) {
	var res = "";
	for ( var i = 0; i < monitors.length; i++) {
		res += monitorResultsToString(monitors[i]);
		res += "\n";
	}
	if (clean) {
		cleanAllMonitorResults();
	}
	return res;
}

/**
 * Returns total (summarized) monitored results
 * 
 * @param clean
 *            (optional) if given, it is forcing to clear all accumulated data after composing a summarized result
 *            string
 * @returns {String} the total monitored result string
 */
function getMonitorTotalResult(clean) {
	var sum = createMon();
	for ( var i = 0; i < monitors.length; i++) {
		var mon = monitors[i];
		if (sum['listen'].length <= 0) {
			sum['listen'] = mon['listen'];
		} else {
			sum['listen'] += ',' + mon['listen'];
		}
		sum['min_time'] = Math.min(sum['min_time'], mon['min_time']);
		sum['max_time'] = Math.max(sum['max_time'], mon['max_time']);
		sum['time'] += mon['time'];
		sum['min_net_time'] = Math.min(sum['min_net_time'], mon['min_net_time']);
		sum['max_net_time'] = Math.max(sum['max_net_time'], mon['max_net_time']);
		sum['net_time'] += mon['net_time'];
		sum['min_resp_time'] = Math.min(sum['min_resp_time'], mon['min_resp_time']);
		sum['max_resp_time'] = Math.max(sum['max_resp_time'], mon['max_resp_time']);
		sum['resp_time'] += mon['resp_time'];
		sum['exceptions'] += mon['exceptions'];
		sum['active'] += mon['active'];
		sum['requests'] += mon['requests'];
		sum['post_count'] += mon['post_count'];
		sum['get_count'] += mon['get_count'];
		sum['bytes_read'] += mon['bytes_read'];
		sum['bytes_written'] += mon['bytes_written'];
		sum['1xx'] += mon['1xx'];
		sum['2xx'] += mon['2xx'];
		sum['3xx'] += mon['3xx'];
		sum['4xx'] += mon['4xx'];
		sum['5xx'] += mon['5xx'];
		sum['timeout'] += mon['timeout'];
		sum['timeS'] = Math.min(sum['timeS'], mon['timeS']);
		sum['timeE'] = Math.max(sum['timeE'], mon['timeE']);

		sum.info.addAll(mon.info);
	}
	if (sum['active'] <= 0) {
		sum['avr_time'] = 0;
		sum['avr_resp_time'] = 0;
		sum['avr_net_time'] = 0;
	} else {
		sum['avr_time'] = sum['time'] / sum['requests'];
		sum['avr_resp_time'] = sum['resp_time'] / sum['requests'];
		sum['avr_net_time'] = sum['net_time'] / sum['requests'];
	}
	if (clean) {
		cleanAllMonitorResults();
	}
	if (sum['listen'].length == 0) {
		sum['status'] = STATUS_DOWN;
	} else if (sum['requests'] == 0) {
		sum['status'] = STATUS_IDLE;
	} else if ((sum['max_net_time'] != 0 && sum['avr_net_time'] / sum['max_net_time'] > 0.9)
			|| (sum['max_resp_time'] != 0 && sum['avr_resp_time'] / sum['max_resp_time'] > 0.9)) {
		sum['status'] = STATUS_NOK;
	} else {
		sum['status'] = STATUS_OK;
	}
	return monitorResultsToString(sum);
}

function getMonitorResults(server) {
	var ret = "";
	if (server && monitors.length > 0) {
		for ( var i = 0; i < monitors.length; i++) {
			var mon_server = monitors[i];
			if (mon_server['server'] == server) {
				ret = monitorResultsToString(mon_server);
				break;
			}
		}
	}
	return ret;
}

/**
 * Returns the composed string in the following form
 * 
 * <fixed part of data> | <flexible (optional part of data)>
 * 
 * where the fixed part item has key:value form and flexible part represents in JSON form like
 * {name1:{name11:value11,...},name2:{name21:vale21,...}...}
 * 
 * @param mon_server
 *            the collecting monitored data structure
 * @returns composed string that represents a monitoring data
 */
/*
 * 
 * declare -r P0="status:status::3;uptime:uptime::3" declare -r P1="avr_resp:avr_resp:s:4;max_resp:max_resp:s:4" declare
 * -r P11="avr_net:avr_net:s:4;max_net:max_net:s:4" declare -r P12="avr_total:avr_total:s:4;max_total:max_total:s:4"
 * declare -r P2="in_rate:in_rate:kbps:4;out_rate:out_rate:kbps:4" declare -r
 * P3="active:active:percent:4;load:load:reqps:4" declare -r RESULT_PARAMS="$P0;$P1;$P11;$P12;$P2;$P3"
 * 
 */
function monitorResultsToString(mon_server) {
	var time_window = ((new Date().getTime()) - mon_server['timeS']) / 1000; // monitoring time window in sec
	var time_idle = time_window - mon_server['active'];
	var load = mon_server['requests'] / time_window;
	ret = "status:" + mon_server['status'] + ";uptime:" + escape(utils.formatTimestamp(process.uptime()))
	// + ";min_net:"+(mon_server['min_net_time']==max_value?0:(mon_server['min_net_time']/1000)).toFixed(3)
	+ ";avr_net:" + (mon_server['avr_net_time'] / 1000).toFixed(3) + ";max_net:"
			+ (mon_server['max_net_time'] / 1000).toFixed(3)
			// + ";min_resp:"+(mon_server['min_resp_time']==max_value?0:(mon_server['min_resp_time']/1000)).toFixed(3)
			+ ";avr_resp:" + (mon_server['avr_resp_time'] / 1000).toFixed(3) 
			+ ";max_resp:" + (mon_server['max_resp_time'] / 1000).toFixed(3)
			// + ";min_total:"+(mon_server['min_time']==max_value?0:(mon_server['min_time']/1000)).toFixed(3)
			+ ";avr_total:" + (mon_server['avr_time'] / 1000).toFixed(3) 
			+ ";max_total:" + (mon_server['max_time'] / 1000).toFixed(3) 
			+ ";in_rate:" + ((mon_server['bytes_read'] / time_window / 1000).toFixed(3)) 
			+ ";out_rate:" + ((mon_server['bytes_written'] / time_window / 1000).toFixed(3)) 
			+ ";active:" + (mon_server['active'] / time_window * 100).toFixed(2) 
			+ ";load:" + (load).toFixed(3);
	// + ";OFD:"+OFD;
	if (mon_server['requests'] > 0) {
		mon_server['info'].add('platform', "total", mon_server['requests']);
		mon_server['info'].add("codes", "1xx", mon_server['1xx']);
		mon_server['info'].add("codes", "2xx", mon_server['2xx']);
		mon_server['info'].add("codes", "3xx", mon_server['3xx']);
		mon_server['info'].add("codes", "4xx", mon_server['4xx']);
		mon_server['info'].add("codes", "408", mon_server['timeout']);
		mon_server['info'].add("codes", "5xx", mon_server['5xx']);
		mon_server['info']['post'] = ((mon_server['post_count'] / mon_server['requests'] * 100)).toFixed(1);
		mon_server['info']['2xx'] = (100 * mon_server['2xx'] / mon_server['requests']).toFixed(1);
		mon_server['info']['exc'] = mon_server['exceptions'];
	}
	mon_server['info']['mon_time'] = (time_window).toFixed(3);
	mon_server['info']["listen"] = '{' + mon_server['listen'] + '}';
	ret += " | " + JSON.stringify(mon_server['info']).toString(); // additional (variable part) results
	return ret;
}

function cleanAllMonitorResults() {
	for ( var i = 0; i < monitors.length; i++) {
		monitors[i] = monitorResultsClean(monitors[i]);
	}
}

function cleanMonitorResults(server) {
	var ret = false;

	if (server && monitors.length > 0) {
		for ( var i = 0; i < monitors.length; i++) {
			if (monitors[i]['server'] == server) {
				monitors[i] = monitorResultsClean(monitors[i]);
				ret = true;
				break;
			}
		}
	}
	return ret;
}

function monitorResultsClean(mon_server) {
	var server = mon_server['server'];
	var listen = mon_server['listen'];
	var timeS = mon_server['timeS'];

	var mon = createMon();

	mon['server'] = server;
	mon['listen'] = listen;
	mon['timeE'] = timeS;
	return mon;
}

/**
 * Composes the flexible info part of data NOTE: this part is very specific and depends on possible server requests
 * 
 * @param request
 *            {Object} the HTTP(S) request object that holds a required information
 * @param collect_all
 *            {boolean} true value indicates to collecting all possible information
 * @returns the composed flexible info object
 */
function getRequestInfo(request, collect_all) {
	var tmp = createMon();
	var headers = request.headers;
	if (typeof(headers) == 'object') {
		var value = headers['mon-platform'];
		if (value && value.length > 0) {
			tmp.info.add('platform', value);
		}
		value = headers['mon-version'];
		if (value && value.length > 0) {
			tmp.info.add('version', value);
		}
		if (collect_all) {
			value = headers['mon-email'] || headers['info']['us'];
			if (value && value.length > 0) {
				tmp.info.add('email', value);
			}
			value = headers['mon-aname'] || headers['info']['ag'];
			if (value && value.length > 0) {
				tmp.info.add('aname', value);
			}
		}
	}
	return tmp.info;
}

/**
 * 
 * @param req
 * @returns OBJECT with user info
 */
function getUserInfo(req) {
	var tmp = {};
	var headers = req.headers;
	if (typeof(headers) == 'object') {
		var value = utils.getClientIp(req);
		if (value && value.length > 0) {
			tmp['ip'] = value;
		}
		value = headers['host'];
		if (value && value.length > 0) {
			tmp['host'] = value;
		}
	}
	return tmp;
}

/**
 * Main Monitor class
 * 
 * This method should only be called when server wants to be under monitoring *
 * 
 * @param server
 *            {Object} to be under monitoring
 * @param options
 *            {Object} the options for given server monitor 
 *            {'collect_all': ('yes' | 'no'), 'top':{'max':<value>, 'limit':<value>}} 
 *            where top.max - the maximum number of collected requests that spent most time for execution 
 *            top.limit - the monitor have to collect info when exceeding the number of specified seconds only
 *            default - {'collect_all': 'no', 'top':{'max':3, 'limit':3}}
 */
var Monitor = exports.Monitor = function(server, options) {
	var mon_server = addToMonitors(server, options);
	if (mon_server && mon_server != null) {
		var host = server.address()['address'] || 'localhost';
		var port = server.address()['port'] || "??";

		// listener for requests
		server.on('request', function(req, res) {

			var params = {};
			params['timeS'] = new Date().getTime();//
			params['Host'] = /* host + ":" + */port;
			// params['Scheme'] = "HTTP";
			params['Method'] = req.method;
			params["content-length"] = req.headers['content-length'];
			params['info'] = getRequestInfo(req, mon_server['collect_all']);
			params['user'] = getUserInfo(req);

			// params['memory'] = sys.inspect(process.memoryUsage());
			// params['free'] = os.freemem()/os.totalmem()*100;
			// params['cpu'] = sys.inspect(os.cpus());

			req.on('add_data', function(obj) {
			params['net_time'] = obj['net_time'] || 0;
			})

			req.on('end', function() {
				var net_time = new Date().getTime();
				params['net_time'] = net_time;
			})

			var socket = req.socket;
			var csocket = req.connection.socket;
			// listener for response finishing
			if (req.socket) {
				req.socket.on('error', function(err) {
					console.error("******SOCKET.ERROR****** " + err + " - " + (new Date().getTime() - params['timeS'])/*+err.stack*/);
				})
				req.socket.on('close', function() {
					params['timeE'] = new Date().getTime();
					params['pure_duration'] = (params['timeE'] - (params['net_time'] || params['timeE']));
					params['net_duration'] = ((params['net_time'] || params['timeE']) - params['timeS']);
					params['total_duration'] = (params['timeE'] - params['timeS']);

					try {
						params['Read'] = socket.bytesRead || csocket.bytesRead;
					} catch (err) {
						params['Read'] = 0;
					}
					try {
						params['Written'] = socket.bytesWritten || csocket.bytesWritten;
					} catch (err) {
						params['Written'] = 0;
					}
					try {
						params['Status'] = res.statusCode;
					} catch (err) {
						params['Status'] = 0;
					}
					params['Uptime'] = process.uptime();

					if (params['Written'] == 0) {
						console.error("\"Written\":0 " + JSON.stringify(res['_headers']));
					}
					console.log("***SOCKET.CLOSE: " + JSON.stringify(params));
					addResultsToMonitor(server, 1, (req.method == "POST" ? 1 : 0), (req.method == "GET" ? 1 : 0),
							params['net_duration'], params['pure_duration'], params['total_duration'], params['Read'],
							params['Written'], params['Status'], params['info'], params['user'], function(error) {
								if (error)
									log_error.error("Monitor[638]: SOCKET.CLOSE-addResultsToMonitor: error while add");
							});
				})
			} else {
				res.on('finish', function() {
					params['timeE'] = new Date().getTime();
					params['pure_duration'] = (params['timeE'] - (params['net_time'] || params['timeE']));
					params['net_duration'] = ((params['net_time'] || params['timeE']) - params['timeS']);
					params['total_duration'] = (params['timeE'] - params['timeS']);

					try {
						params['Read'] = socket.bytesRead || csocket.bytesRead;
					} catch (err) {
						params['Read'] = 0;
					}
					try {
						params['Written'] = socket.bytesWritten || csocket.bytesWritten;
					} catch (err) {
						params['Written'] = 0;
					}
					try {
						params['Status'] = res.statusCode;
					} catch (err) {
						params['Status'] = 0;
					}
					params['Uptime'] = process.uptime();// (timeE - time_start) / 1000;// uptime in sec

					console.log("***RES.FINISH: " + JSON.stringify(params));
					addResultsToMonitor(server, 1, (req.method == "POST" ? 1 : 0), (req.method == "GET" ? 1 : 0),
							params['net_duration'], params['pure_duration'], params['total_duration'], params['Read'],
							params['Written'], params['Status'], params['info'], params['user'], function(error) {
								if (error)
									log_error.error("Monitor[670]: RES.FINISH-addResultsToMonitor: error while add");
							});
				});
			}
		});

		// server.on('additional', function(obj){
		// addData(server, obj);
		// })

		// listener for server closing
		server.on('close', function(errno) {
			removeFromMonitor(server);
		})

		events.EventEmitter.call(this);
	}
}

sys.inherits(Monitor, events.EventEmitter);

function checkAccess(access_code) {
	if (access_code	&& access_code == "monitis") {
		return true;
	}
	return false;
}

function obtainOFD(callback) {
	var df = -1;
	// var cmd_ofd = "lsof -p" + process.pid + " | wc -l";//command to retrieve the count of open file descriptors
	var cmd_ofd = "ls /proc/" + process.pid + "/fd | wc -l";// command to retrieve the count of open file descriptors
	require('child_process').exec(cmd_ofd, function(error, stdout, stderr) {
		df = stdout.replace(/[\s]/g, '');
		if (!error && df.length > 0 && !isNaN(df)) {
			OFD = df;
		} 
		if (callback)
			return callback();
	});
}

/**
 * HTTP Server that is returning the summarized monitored data
 * 
 * The request should have the following form:
 * 
 * http://127.0.0.1:10010/node_monitor?action=getdata&access_code={monitis | <access code>}
 * 
 */
http.createServer(function(req, res) {
	// obtainOFD(function(){
	var pathname = url.parse(req.url, true).pathname.replace("/", "").trim().toLowerCase();
	var query = url.parse(req.url, true).query;
	if (pathname && pathname == "node_monitor" && query && query['action'] && query['access_code']) {
		var action = query['action'].trim().toLowerCase();
		var access_code = query['access_code'].trim().toLowerCase();
	}
	var result = "???";
	var code = 200;
	if (access_code	&& access_code == "monitis") {
		switch (action) {
		case 'getadata':
			result = "Not yet implemented.";
			break;
		case 'getdata':
			result = getMonitorTotalResult(true);
			break;
		default:
			result = "wrong command received";
			code = 400;
		}

	} else {
		result = "Access denied."
		code = 403;
	}
	console.log("SUM: " + result);

	res.writeHead(200, {
		'Content-Type' : 'text/plain',
		'connection' : 'close'
	});
	res.write(result);
	res.end();
}).listen(PORT_LISTEN, HOST_LISTEN);
