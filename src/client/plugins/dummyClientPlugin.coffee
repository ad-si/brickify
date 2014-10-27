module.exports.pluginName = 'Dummy Client Plugin'

module.exports.init = () ->
	console.log 'Dummy Client Plugin initialization'

module.exports.handleStateChange = (delta, state) ->
	console.log 'Dummy Plugin changes ClientModified to true'
	state.dummyPluginClientModifiedIt = true
