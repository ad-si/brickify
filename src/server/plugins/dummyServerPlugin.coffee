module.exports.pluginName = 'Dummy Server Plugin'

module.exports.init = () ->
	console.log 'Dummy Server Plugin initialization'

module.exports.handleStateChange = (delta, state) ->
	console.log 'Dummy Plugin got a state change'
	state.dummyPluginModifiedIt = true