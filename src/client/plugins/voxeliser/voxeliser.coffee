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
BrickSystem = require './bricks/BrickSystem'
BrickLayout = require './bricks/BrickLayout'
BrickLayouter = require './bricks/BrickLayouter'
Voxeliser = require './geometry/Voxeliser'
voxeliser = null

voxelRenderer = require './rendering/voxelRenderer'
ColorPalette = require './rendering/ColorPalette'

threejsRootNode = null
statesync = require '../../statesync'
stateInstance = null
voxelisedBrickSpaceGrid = null

module.exports.pluginName = 'Voxeliser Plugin'
module.exports.category = common.CATEGORY_CONVERTER

module.exports.init = () ->
	statesync.getState(setState)

module.exports.init3D = (threejsNode) ->
	threejsRootNode = threejsNode

module.exports.onUiInit = (elements) ->
	elements.toolsContainer.innerHTML =
		'<button id="voxeliseButton" type="button"
		class="btn btn-default">Voxelise</button>
		<button id="layoutButton" type="button"
		class="btn btn-default">Layout</button>'
	$('#voxeliseButton').click((event) ->
		event.stopPropagation()
		startVoxelisation()
		)
	$('#layoutButton').click((event) ->
		event.stopPropagation()
		layout()
		)
	return

setState = (state) ->
	stateInstance = state

voxelise = (optimizedModel, brickSystem) ->
	voxeliser ?= new Voxeliser
	solidObject3D = Converter.convertToSolidObject3D(optimizedModel)
	voxelisedBrickSpaceGrid = voxeliser.voxelise(solidObject3D, brickSystem)
	voxelisedBrickSpaceGrid.set_Color ColorPalette.orange()
	threejsRootNode.add voxelRenderer voxelisedBrickSpaceGrid

layout = () ->
	layout = new BrickLayout(voxelisedBrickSpaceGrid)
	layouter = new BrickLayouter(layout)
	layouter.layoutAll()
	threejsRootNode.add layout.get_SceneModel()

startVoxelisation = () ->
	if stateInstance
		#todo, handle if stateInstance undefined
		for node in stateInstance.rootNode.childNodes
			modelCache.requestOptimizedMeshFromServer node.pluginData[0].value.meshHash,
			(modelInstance) ->
				Lego = new BrickSystem( 8, 8, 3.2, 1.7, 2.512)
				Lego.add_BrickTypes [
					[1,1,1],[1,2,1],[1,3,1],[1,4,1],[1,6,1],[1,8,1],[2,2,1],[2,3,1],
					[2,4,1],[2,6,1],[2,8,1],[2,10,1],[1,1,3],[1,2,3],[1,3,3],[1,4,3],
					[1,6,3],[1,8,3],[1,10,3],[1,12,3],[1,16,3],[2,2,3],[2,3,3],[2,4,3],
					[2,6,3],[2,8,3],[2,10,3]
				]
				voxelise modelInstance, Lego
