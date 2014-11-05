logger = require 'winston'

module.exports.pluginName = 'Dummy Server Plugin'

module.exports.init = () ->
	logger.debug 'Dummy Server Plugin initialization'

module.exports.handleStateChange = (delta, state) ->
	logger.debug 'Dummy Server Plugin state change'
