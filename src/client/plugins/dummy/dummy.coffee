common = require '../../../common/pluginCommon'

module.exports.pluginName = 'Dummy Client Plugin'
module.exports.category = common.CATEGORY_IMPORT

#Called when the plugin is initialized.
#You should create your plugin dependent datastructures here
module.exports.init = (globalConfig, stateSync) ->
	console.log 'Dummy Client Plugin initialization'

#Called when the plugin is initialized.
#You should create your visible geometry
#and add it as a child to the node here
module.exports.init3d = (threejsNode) ->
	console.log 'Dummy Client Plugin initializes 3d'

# Is called when the server changes the state,
# where state is the new state and delta the difference to the old state
module.exports.handleStateChange = (delta, state) ->
	console.log 'Dummy Client Plugin state change'

#if set to true, update3D() will be called every frame
#consider setting it to false to improve performance
module.exports.needs3dAnimation = false

# Is called every frame
# Use it for animations or updates that have to be performed every frame
module.exports.update3D = () ->
