module.exports.pluginName = 'Dummy Client Plugin'

module.exports.init = () ->
	console.log 'Dummy Client Plugin initialization'

module.exports.handleStateChange = (delta, state) ->
	console.log 'Dummy Plugin got a state change'
	state.dummyPluginModifiedIt = true