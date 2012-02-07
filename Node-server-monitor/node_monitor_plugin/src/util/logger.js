var path = require('path')
	,fs = require('fs')
	,log4js = require('log4js');

/**
 * Searching of properties file beginning from 'start_dir' and continue up to specified 'end_dir'. 
 * At the return the properties object will be loaded if success (otherwise it will be untouched)
 */
function search_file(file_path){
	var end_dir = '/';			//root folder as the end dir of searching
	var start_dir = __dirname;	//current folder as the start dir of searching
	
	var file = undefined;
	var _file;
	var cur_path = start_dir; // current folder
	while (cur_path != end_dir) {
		_file = path.normalize(path.resolve(cur_path, '..', file_path));
		if (path.existsSync(_file)) {
			file = _file;
			break;
		} else {
//			console.log("NOT found "+_file);
			cur_path = path.join(cur_path, '..');
		}
	}
	return file;
}

//source parameters
var log_conf ='./properties/log4js.json';//relative path to the properties file (JSON)
var conf_file = search_file(log_conf);
if (conf_file){
	log4js.configure(conf_file, {});
}

var Logger = function(logger_name){
	var log = log4js.getLogger(logger_name);
	log.info(">>>>>>>>> Logger for '"+log.getName()+"' initialized with success. Log Level: "+log.getLevel().toString()+"<<<<<<<<<");
	return log;
}

exports.Logger = Logger;

//levels = {
//    ALL: new Level(Number.MIN_VALUE, "ALL", "grey"),
//    TRACE: new Level(5000, "TRACE", "blue"),
//    DEBUG: new Level(10000, "DEBUG", "cyan"),
//    INFO: new Level(20000, "INFO", "green"),
//    WARN: new Level(30000, "WARN", "yellow"),
//    ERROR: new Level(40000, "ERROR", "red"),
//    FATAL: new Level(50000, "FATAL", "magenta"),
//    OFF: new Level(Number.MAX_VALUE, "OFF", "grey")  
//}

