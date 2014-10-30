common = require '../../common/pluginCommon'

module.exports.pluginName = 'Dummy Client Plugin'
module.exports.category = common.CATEGORY_IMPORT

module.exports.init = (ui, stateSync) ->
	console.log 'Dummy Client Plugin initialization'

module.exports.handleStateChange = (delta, state) ->
	console.log 'Dummy Client Plugin state change'
