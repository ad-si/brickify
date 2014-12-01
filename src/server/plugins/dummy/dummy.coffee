# Colorful logger for console
winston = require 'winston'
logger = winston.loggers.get('log')

common = require '../../../common/pluginCommon'

module.exports.pluginName = 'Dummy Server Folder-Plugin'
module.exports.category = common.CATEGORY_DUMMY

module.exports.init = () ->
	logger.debug 'Dummy Server Folder-Plugin initialization'

module.exports.onStateUpdate = (delta, state) ->
	logger.debug 'Dummy Server Folder-Plugin state change'
