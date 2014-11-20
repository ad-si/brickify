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
#BrickSystems = require './bricks/BrickSystems'
BrickSystem = require './bricks/BrickSystem'
Voxeliser = require './geometry/Voxeliser'
voxeliser = null

voxelRenderer = require './rendering/voxelRenderer'

threejsRootNode = null
stateInstance = null
globalConfigInstance = null

module.exports.pluginName = 'Voxeliser Plugin'
module.exports.category = common.CATEGORY_CONVERTER

module.exports.init = (globalConfig, stateSync, ui) ->
	stateInstance = stateSync
	globalConfigInstance = globalConfig

module.exports.init3D = (threejsNode) ->
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
		modelCache.requestOptimizedMeshFromServer node.pluginData[0].value.meshHash,
			(modelInstance) ->
				Lego = new BrickSystem( 8, 8, 3.2, 1.7, 2.512)
				Lego.add_BrickTypes [
					[1,1,1],[1,2,1],[1,3,1],[1,4,1],[1,6,1],[1,8,1],[2,2,1],[2,3,1],[2,4,1],[2,6,1],[2,8,1],[2,10,1],
					[1,1,3],[1,2,3],[1,3,3],[1,4,3],[1,6,3],[1,8,3],[1,10,3],[1,12,3],[1,16,3],[2,2,3],[2,3,3],[2,4,3],[2,6,3],[2,8,3],[2,10,3]
				]
				
				voxelise modelInstance, Lego


###
# On each render frame the renderer will call the `update3D`
# method of all plugins that provide it. There are no arguments passed.
#
# @memberOf dummyClientPlugin
# @see render
###
# module.exports.update3D = () ->

voxelise = (optimizedModel, brickSystem) ->
	voxeliser ?= new Voxeliser
	# convert optimizedModel to solidObject3D
	solidObject3D = Converter.convertToSolidObject3D(optimizedModel)
	voxelisedModel = voxeliser.voxelise(solidObject3D, brickSystem)
	threejsRootNode.add voxelRenderer voxelisedModel
