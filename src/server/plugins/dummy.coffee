# Colorful logger for console
winston = require 'winston'
logger = winston.loggers.get('log')

common = require '../../common/pluginCommon'

module.exports.pluginName = 'Dummy Server File-Plugin'
module.exports.category = common.CATEGORY_DUMMY

module.exports.init = () ->
	logger.debug 'Dummy Server File-Plugin initialization'

module.exports.handleStateChange = (delta, state) ->
	logger.debug 'Dummy Server File-Plugin state change'
