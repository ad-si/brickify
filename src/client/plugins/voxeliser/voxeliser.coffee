###
	#Voxeliser Plugin#
###

###
#
# a voxelising plugin imported from the faBrickator projekt
#
###

objectTree = require '../../../common/objectTree'
statesync = require '../../statesync'
modelCache = require '../../modelCache'
OptimizedModel = require '../../../common/OptimizedModel'
BrickSystem = require './bricks/BrickSystem'
BrickLayout = require './bricks/BrickLayout'
BrickLayouter = require './bricks/BrickLayouter'
Voxeliser = require './geometry/Voxeliser'
voxelRenderer = require './rendering/voxelRenderer'
interactionHelper = require '../../interactionHelper'

threejsRootNode = null
stateInstance = null
voxelisedModels = []
voxeliser = null
lego = null

module.exports.pluginName = 'Voxeliser Plugin'
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

module.exports.onClick = (event) ->
	intersects =
		interactionHelper.getPolygonClickedOn(event, threejsRootNode.children)
	if (intersects.length > 0)
		intersects[0].object.material.color.set(new THREE.Color(1, 0, 0))
	console.log intersects

# Traverses the state and start the voxelisation of all stlImported Models
voxeliseAllModels = () ->
	if stateInstance

		onSuccess = (node) ->
			modelCache.request(
				node.meshHash
				(model) ->
					voxelise model, node
				() -> console.warn 'could no get model')

		objectTree.forAllSubnodes(
			stateInstance.rootNode
			onSuccess
		)

# voxelises a single model
voxelise = (optimizedModel, node) ->
	# check if model was already voxelised
	for data in voxelisedModels
		if data.node.meshHash is node.meshHash
			console.warn 'already voxelised this model'
			return

	voxeliser ?= new Voxeliser
	if not lego
		lego = new BrickSystem( 8, 8, 3.2, 1.7, 2.512)
		lego.add_BrickTypes [
				[1,1,1],[1,2,1],[1,3,1],[1,4,1],[1,6,1],[1,8,1],[2,2,1],[2,3,1],
				[2,4,1],[2,6,1],[2,8,1],[2,10,1],[1,1,3],[1,2,3],[1,3,3],[1,4,3],
				[1,6,3],[1,8,3],[1,10,3],[1,12,3],[1,16,3],[2,2,3],[2,3,3],[2,4,3],
				[2,6,3],[2,8,3],[2,10,3]
			]

	grid = voxeliser.voxelise(optimizedModel, lego)

	voxelisedData = new VoxeliserData(node, grid, voxelRenderer grid, null, null)
	voxelisedModels.push voxelisedData
	threejsRootNode.add voxelisedData.gridForThree

#layouts all voxelised Models
layout = () ->
	if not voxelisedModels.length > 0
		console.warn 'trying to layout, but no voxelisedModels available'
	else
		for data in voxelisedModels when data.layout is null
			legoLayout = new BrickLayout(data.grid)
			layouter = new BrickLayouter(legoLayout)
			layouter.layoutAll()
			legoMesh = legoLayout.get_SceneModel()
			data.addLayout(legoLayout, legoMesh)

			threejsRootNode.remove data.gridForThree
			threejsRootNode.add data.layoutForThree

# Helper Class that - after voxelising and layouting -
# contains the voxelised grid, it's ThreeJS representation
# and the ThreeJs
class VoxeliserData
	constructor: (@node, @grid, @gridForThree,
	        @layout = null, @layoutForThree = null) ->
	    return
	addLayout: (@layout, @layoutForThree) -> return
