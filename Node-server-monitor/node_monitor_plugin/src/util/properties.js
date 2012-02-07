/**
 * JSON properties file reader
 */
var fs = require('fs'),
  path = require('path'),
  logger = require('../util/logger').Logger('node_properties');

var properties = {};

//source parameters
var properties_file ='./properties/mconfig.json';//relative path to the default properties file (JSON)
//var end_dir = process.env.HOME;	//user's home folder as the end dir of searching
var end_dir = '/';			//root folder as the end dir of searching
var start_dir = __dirname;	//current folder as the start di of searching

var file = '';//at the end of finding loop it will contain an absolute path to the properties file (if found)

/**
 * Searching of properties file beginning from 'start_dir' and continue up to specified 'end_dir'. 
 * At the return the properties object will be loaded if success (otherwise it will be untouched)
 */
var cur_path = start_dir; // current folder
while (cur_path != end_dir) {
	file = path.join(cur_path, '..', properties_file);
	if (path.existsSync(file)) {
		logger.info("Opening confihuration file: " + file);
		try {
			properties = JSON.parse(fs.readFileSync(file, 'utf8'));
		} catch (err) {
			logger.error("JSON parse error - " + err + "\n\twhile processing file " + file);
		}
		break;
	} else {
		/* DEBUG logger.info("NOT found "+file); */
		cur_path = path.join(cur_path, '..');
	}
}

var l = Object.keys(properties).length;
if (l > 0) {
	logger.info("Configuration file (" + file + ") is loaded. "+l+" properties were read.");
	logger.info(JSON.stringify(properties, function(key, value){return value;}, 2));
} else {
	logger.error("ERROR: The searching process has reached up to '"+end_dir+"' folder, but configuration file (" + file + ") had not been found or corrupted.");
}

module.exports = properties;

