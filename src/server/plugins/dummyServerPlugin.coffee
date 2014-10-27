module.exports.pluginName = 'Dummy Server Plugin'

module.exports.init = () ->
	console.log 'Dummy Server Plugin initialization'

module.exports.handleStateChange = (delta, state) ->
	if state.dummyPluginClientModifiedIt == true
		console.log 'Dummy Server Plugin changes its state after client changed it'
		state.dummyServerPluginModifiedIt = true