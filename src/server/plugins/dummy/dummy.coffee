# Colorful logger for console
winston = require 'winston'
logger = winston.loggers.get('log')

module.exports.init = () ->
	logger.debug 'Dummy Server Folder-Plugin initialization'

module.exports.onStateUpdate = (state) ->
	logger.debug 'Dummy Server Folder-Plugin state change'
