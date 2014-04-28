
/**
 * Searching of specified file/dir beginning from 'start_dir' up to 'end_dir'. 
 * 
 * At the end of search the full path will returned on success.
 * The default path (def-file_path) can be specified. it will return on search failed.
 */
function search_file(file_path, def_file_path){
	var end_dir = '/';			//root folder as the end dir of searching
	var start_dir = __dirname;	//current folder as the start dir of searching
	
	var file = undefined;
	var _file;
	var cur_path = start_dir; // current folder
	while (cur_path != end_dir) {
		_file = path.normalize(path.resolve(cur_path, '..', file_path));
		if (fs.existsSync(_file)) {
			file = _file;
//			console.log("FOUND: "+file);
			break;
		} else {
//			console.log("NOT found "+_file);
			cur_path = path.join(cur_path, '..');
		}
	}
	return file || def_file_path;
}
exports.search_file = search_file;

// Return the name of a function (may be "") or null for nonfunctions
Function.prototype.getName = function() {
	if ("name" in this) return this.name;
	return this.name = this.toString().match(/function\s*([^(]*)\(/)[1];
};
	

/**
sprintf() for JavaScript 0.7-beta1
http://www.diveintojavascript.com/projects/javascript-sprintf

sprintf() for JavaScript is a complete open source JavaScript sprintf implementation.

It's prototype is simple:

string sprintf(string format , [mixed arg1 [, mixed arg2 [ ,...]]]);
The placeholders in the format string are marked by "%" and are followed by one or more of these elements, in this order:

An optional "+" sign that forces to preceed the result with a plus or minus sign on numeric values. 
By default, only the "-" sign is used on negative numbers.

An optional padding specifier that says what character to use for padding (if specified). 
Possible values are 0 or any other character precedeed by a '. The default is to pad with spaces.

An optional "-" sign, that causes sprintf to left-align the result of this placeholder. 
The default is to right-align the result.

An optional number, that says how many characters the result should have. 
If the value to be returned is shorter than this number, the result will be padded.

An optional precision modifier, consisting of a "." (dot) followed by a number, 
that says how many digits should be displayed for floating point numbers. 
When used on a string, it causes the result to be truncated.

A type specifier that can be any of:
% - print a literal "%" character
b - print an integer as a binary number
c - print an integer as the character with that ASCII value
d - print an integer as a signed decimal number
e - print a float as scientific notation
u - print an integer as an unsigned decimal number
f - print a float as is
o - print an integer as an octal number
s - print a string as is
x - print an integer as a hexadecimal number (lower-case)
X - print an integer as a hexadecimal number (upper-case)
**/
var sprintf = (function() {
	function get_type(variable) {
		return Object.prototype.toString.call(variable).slice(8, -1).toLowerCase();
	}
	function str_repeat(input, multiplier) {
		for (var output = []; multiplier > 0; output[--multiplier] = input) {/* do nothing */}
		return output.join('');
	}

	var str_format = function() {
		if (!str_format.cache.hasOwnProperty(arguments[0])) {
			str_format.cache[arguments[0]] = str_format.parse(arguments[0]);
		}
		return str_format.format.call(null, str_format.cache[arguments[0]], arguments);
	};

	str_format.format = function(parse_tree, argv) {
		var cursor = 1, tree_length = parse_tree.length, node_type = '', arg, output = [], i, k, match, pad, pad_character, pad_length;
		for (i = 0; i < tree_length; i++) {
			node_type = get_type(parse_tree[i]);
			if (node_type === 'string') {
				output.push(parse_tree[i]);
			}
			else if (node_type === 'array') {
				match = parse_tree[i]; // convenience purposes only
				if (match[2]) { // keyword argument
					arg = argv[cursor];
					for (k = 0; k < match[2].length; k++) {
						if (!arg.hasOwnProperty(match[2][k])) {
							throw(sprintf('[sprintf] property "%s" does not exist', match[2][k]));
						}
						arg = arg[match[2][k]];
					}
				}
				else if (match[1]) { // positional argument (explicit)
					arg = argv[match[1]];
				}
				else { // positional argument (implicit)
					arg = argv[cursor++];
				}

				if (/[^s]/.test(match[8]) && (get_type(arg) != 'number')) {
					throw(sprintf('[sprintf] expecting number but found %s', get_type(arg)));
				}
				switch (match[8]) {
					case 'b': arg = arg.toString(2); break;
					case 'c': arg = String.fromCharCode(arg); break;
					case 'd': arg = parseInt(arg, 10); break;
					case 'e': arg = match[7] ? arg.toExponential(match[7]) : arg.toExponential(); break;
					case 'f': arg = match[7] ? parseFloat(arg).toFixed(match[7]) : parseFloat(arg); break;
					case 'o': arg = arg.toString(8); break;
					case 's': arg = ((arg = String(arg)) && match[7] ? arg.substring(0, match[7]) : arg); break;
					case 'u': arg = Math.abs(arg); break;
					case 'x': arg = arg.toString(16); break;
					case 'X': arg = arg.toString(16).toUpperCase(); break;
				}
				arg = (/[def]/.test(match[8]) && match[3] && arg >= 0 ? '+'+ arg : arg);
				pad_character = match[4] ? match[4] == '0' ? '0' : match[4].charAt(1) : ' ';
				pad_length = match[6] - String(arg).length;
				pad = match[6] ? str_repeat(pad_character, pad_length) : '';
				output.push(match[5] ? arg + pad : pad + arg);
			}
		}
		return output.join('');
	};

	str_format.cache = {};

	str_format.parse = function(fmt) {
		var _fmt = fmt, match = [], parse_tree = [], arg_names = 0;
		while (_fmt) {
			if ((match = /^[^\x25]+/.exec(_fmt)) !== null) {
				parse_tree.push(match[0]);
			}
			else if ((match = /^\x25{2}/.exec(_fmt)) !== null) {
				parse_tree.push('%');
			}
			else if ((match = /^\x25(?:([1-9]\d*)\$|\(([^\)]+)\))?(\+)?(0|'[^$])?(-)?(\d+)?(?:\.(\d+))?([b-fosuxX])/.exec(_fmt)) !== null) {
				if (match[2]) {
					arg_names |= 1;
					var field_list = [], replacement_field = match[2], field_match = [];
					if ((field_match = /^([a-z_][a-z_\d]*)/i.exec(replacement_field)) !== null) {
						field_list.push(field_match[1]);
						while ((replacement_field = replacement_field.substring(field_match[0].length)) !== '') {
							if ((field_match = /^\.([a-z_][a-z_\d]*)/i.exec(replacement_field)) !== null) {
								field_list.push(field_match[1]);
							}
							else if ((field_match = /^\[(\d+)\]/.exec(replacement_field)) !== null) {
								field_list.push(field_match[1]);
							}
							else {
								throw('[sprintf] huh?');
							}
						}
					}
					else {
						throw('[sprintf] huh?');
					}
					match[2] = field_list;
				}
				else {
					arg_names |= 2;
				}
				if (arg_names === 3) {
					throw('[sprintf] mixing positional and named placeholders is not (yet) supported');
				}
				parse_tree.push(match);
			}
			else {
				throw('[sprintf] huh?');
			}
			_fmt = _fmt.substring(match[0].length);
		}
		return parse_tree;
	};

	return str_format;
})();

/**
 * vsprintf() is the same as sprintf() except that it accepts an array of arguments, rather than a variable number of arguments:
 *
 *    vsprintf('The first 4 letters of the english alphabet are: %s, %s, %s and %s', ['a', 'b', 'c', 'd']);
 */
var vsprintf = function(fmt, argv) {
	argv.unshift(fmt);
	return sprintf.apply(null, argv);
};
exports.sprintf = sprintf;
exports.vsprintf = vsprintf;

/**
 * Returns IP from HTTP request by using various methods
 */
function getClientIp(req) {
	  var ipAddress;
	  // If there is a proxy we cannot have the client address - just the "localhost" address. 
	  // Fortunately, almost any proxy puts into the request header the client IP-address with key 'x-forwarded-for'. 
	  // So, we need check firstly the proxy forwarded address.
	  // NOTE: Amazon EC2 / Heroku workaround to get real client IP
	  var forwardedIpsStr = req.headers['x-forwarded-for']; 
	  if (forwardedIpsStr) {
	    // 'x-forwarded-for' header may return multiple IP addresses in
	    // the format: "client IP, proxy 1 IP, proxy 2 IP" so take the the first one
	    var forwardedIps = forwardedIpsStr.split(',');
	    ipAddress = forwardedIps[0];
	  }
	  if (!ipAddress && req.connection) {
	    // Ensure getting client IP address still works in
	    // development environment
	    ipAddress = req.connection.remoteAddress;
	    if (!ipAddress && req.connection.socket){
	    	ipAddress = req.connection.socket.remoteAddress;
	    }
	  }
	  if (!ipAddress && req.socket) {
		  ipAddress = req.socket.remoteAddress;
	  }
	  return ipAddress;
	};
exports.getClientIp = getClientIp;


/**
 * Format a timestamp into the form 'x days hh:mm:ss'
 * 
 * @param timestamp
 *            the timestamp in sec
 * @returns formatted string
 */
function formatTimestamp(timestamp){
	var time = timestamp;
	var sec = Math.floor(time%60);
	var min = Math.floor((time/60)%60);
	var hr = Math.floor((time/3600)%24);
	var da = Math.floor(time/86400);
	var str = sprintf("%02d.%'02d.%'02d", hr, min, sec);
	if (da > 0){
		str = da + "-" + str; 
	}
	return str;
}
exports.formatTimestamp = formatTimestamp;
