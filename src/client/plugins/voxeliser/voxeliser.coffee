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
statesync = require '../../statesync'
modelCache = require '../../modelCache'
OptimizedModel = require '../../../common/OptimizedModel'
BrickSystem = require './bricks/BrickSystem'
BrickLayout = require './bricks/BrickLayout'
BrickLayouter = require './bricks/BrickLayouter'
Voxeliser = require './geometry/Voxeliser'
voxelRenderer = require './rendering/voxelRenderer'

threejsRootNode = null
stateInstance = null
voxelisedModels = []
voxeliser = null
lego = null

module.exports.pluginName = 'Voxeliser Plugin'
module.exports.category = common.CATEGORY_CONVERTER
pluginPropertyName = 'voxeliser'

module.exports.init = () ->
	setState = (state) ->
		stateInstance = state
	
	statesync.getState(setState)

module.exports.init3d = (threejsNode) ->
	threejsRootNode = threejsNode

module.exports.initUi = (elements) ->
	elements.toolsContainer.innerHTML =
		'<button id="voxeliseButton" type="button"
		class="btn btn-default">Voxelise</button>
		<button id="layoutButton" type="button"
		class="btn btn-default">Layout</button>'
	$('#voxeliseButton').click((event) ->
		event.stopPropagation()
		voxeliseAllModels()
		)
	$('#layoutButton').click((event) ->
		event.stopPropagation()
		layout()
		)
	return

# Traverses the state and start the voxelisation of all stlImported Models
voxeliseAllModels = () ->
	if stateInstance
		onSuccess = (node) ->
			modelCache.requestOptimizedMeshFromServer(
				node.pluginData.stlImport.meshHash,
				(modelInstance) -> voxelise modelInstance, node
			)

		objectTree.forAllSubnodesWithProperty(
			stateInstance.rootNode
			'stlImport' #todo: remove string literal
			onSuccess
		)

# voxelises a single model
voxelise = (optimizedModel, node) ->
	voxeliser ?= new Voxeliser

	solidObject3D = Converter.convertToSolidObject3D(optimizedModel)

	if not lego
		lego = new BrickSystem( 8, 8, 3.2, 1.7, 2.512)
		lego.add_BrickTypes [
				[1,1,1],[1,2,1],[1,3,1],[1,4,1],[1,6,1],[1,8,1],[2,2,1],[2,3,1],
				[2,4,1],[2,6,1],[2,8,1],[2,10,1],[1,1,3],[1,2,3],[1,3,3],[1,4,3],
				[1,6,3],[1,8,3],[1,10,3],[1,12,3],[1,16,3],[2,2,3],[2,3,3],[2,4,3],
				[2,6,3],[2,8,3],[2,10,3]
			]

	grid = voxeliser.voxelise(optimizedModel, lego)
	voxelisedModels.push grid
	threejsRootNode.add voxelRenderer grid

#layouts all voxelised Models
layout = () ->
	if not voxelisedModels.length > 0
		console.warn 'trying to layout, but no voxelisedModels available'
	else
		for grid in voxelisedModels
				layout = new BrickLayout(grid)
				layouter = new BrickLayouter(layout)
				layouter.layoutAll()
				threejsRootNode.add layout.get_SceneModel()
