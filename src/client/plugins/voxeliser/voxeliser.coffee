###
  #Voxeliser Plugin#
###

###
#
# a voxelising plugin imported from the faBrickator projekt
#
###

common = require '../../../common/pluginCommon'
objectTree = require '../../../common/objectTree'
modelCache = require '../../modelCache'
OptimizedModel = require '../../../common/OptimizedModel'
Converter = require './geometry/Converter'
BrickSystems = require './bricks/BrickSystems'
Voxeliser = require './geometry/Voxeliser'
voxeliser = new Voxeliser

threejsRootNode = null
stateInstance = null
globalConfigInstance = null

module.exports.pluginName = 'Voxeliser Plugin'
module.exports.category = common.CATEGORY_CONVERTER

module.exports.init = (globalConfig, stateSync, ui) ->
	stateInstance = stateSync
	globalConfigInstance = globalConfig

module.exports.init3d = (threejsNode) ->
	threejsRootNode = threejsNode

###
# The state synchronization module will call each plugin's
# `updateState` method (if provided) whenever the current state changes
# due to user input or calculation results on either server or client side.
#
# The hook provides both the delta to the previous state and the new complete
# state as arguments.
#
# @param {Object} delta the state changes since the last updateState call
# @param {Object} state the complete current state
# @memberOf dummyClientPlugin
# @see stateSynchronization
###
module.exports.updateState = (delta, state) ->
	for node in state.rootNode.childNodes
		modelCache.requestMeshFromServer node.pluginData[0].value.meshHash,
			(modelBinaryData) ->
				optimizedModel = new OptimizedModel()
				optimizedModel.fromBase64 modelBinaryData
				voxelise optimizedModel, BrickSystems.Lego
			->
				return


###
# On each render frame the renderer will call the `update3D`
# method of all plugins that provide it. There are no arguments passed.
#
# @memberOf dummyClientPlugin
# @see render
###
# module.exports.update3D = () ->

voxelise = (optimizedModel, brickSystem) ->
	# convert optimizedModel to solidObject3D
	solidObject3D = Converter.convertToSolidObject3D(optimizedModel)
	voxeliser.voxelise(solidObject3D, brickSystem)
