var  http = require('http')
	,https = require('https')
	,fs = require('fs')
	,logger = require('../util/logger').Logger('node_server')
	,monitor = require('../monitor');

var options = {
		https: {/* HTTPS certificates*/
				    key: fs.readFileSync('./.ssh2/privatekey.pem', 'utf8'),
				    cert: fs.readFileSync('./.ssh2/certificate.pem', 'utf8')  
				}
};

//HTTPS test server
var serverS = https.createServer(options.https, function(req, res) {
	setTimeout(function(){
		res.writeHead(202, {
			'Content-Type' : 'text/plain',
			"connection": "close"
		});
		res.write('hello, i am HTTPS.');
		res.end();
	}, 50);
	
}).listen(8443);
logger.info("HTTPS server is created and listen on "+serverS.address()['port']);

monitor.Monitor(serverS);//add server to monitor

//HTTP test server
var server = http.createServer(function(req, res) {
	setTimeout(function(){
		res.writeHead(202, {
			'Content-Type' : 'text/plain',
			"connection": "close"
		});
		res.write('hello, i am HTTP.');
		res.end();
	}, 50);
	
}).listen(8080);
logger.info("HTTP server is created and listen on "+server.address()['port']);


monitor.Monitor(server);//add server to monitor


