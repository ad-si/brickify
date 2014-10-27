logger = require 'winston'

module.exports.pluginName = 'Dummy Server Plugin'

module.exports.init = () ->
	logger.debug 'Dummy Server Plugin initialization'

module.exports.handleStateChange = (delta, state) ->
	if state.dummyPluginClientModifiedIt == true
		logger.debug 'Dummy Server Plugin changes its state after client changed it'
		state.dummyServerPluginModifiedIt = true