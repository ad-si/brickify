###
	#FaBrickatorPlugin Plugin#
###

###
#
# a plugin using imported code from the faBrickator projekt
#
###

objectTree = require '../../common/objectTree'
modelCache = require '../../client/modelCache'
OptimizedModel = require '../../common/OptimizedModel'
BrickSystem = require './bricks/BrickSystem'
BrickLayout = require './bricks/BrickLayout'
BrickLayouter = require './bricks/BrickLayouter'
Voxeliser = require './geometry/Voxeliser'
voxelRenderer = require './rendering/voxelRenderer'
interactionHelper = require '../../client/interactionHelper'
THREE = require 'three'
global.$ = require 'jquery'

pluginPropertyName = 'voxeliser'

module.exports = class FaBrickatorPlugin
	constructor: () ->
		@threejsRootNode = null
		@stateInstance = null
		@voxelisedModels = []
		@voxeliser = null
		@lego = null

	init: () => return

	init3d: (@threejsRootNode, @renderer) => return

	initUi: (domElements) =>
		return

	getUiSchema: () =>
		voxelCallback = (selectedNode) =>
			modelCache.request selectedNode.meshHash, (optimizedModel) =>
				@voxelise optimizedModel, selectedNode

		layoutCallback = (selectedNode) =>
			for data in @voxelisedModels
				if data.node.meshHash is selectedNode.meshHash
					if data.layout == null
						@layout data
					else
						console.warn 'Already created a layout for this model'

		return {
			title: 'Fabrickator'
			type: 'object'
			actions:
				a1:
					title: 'Voxelize'
					callback: voxelCallback
				a2:
					title: 'Layout'
					callback: layoutCallback
		}

	onStateUpdate: (state, done) =>
		@stateInstance = state
		done()


	onClick: (event) =>
		intersects =
			interactionHelper.getPolygonClickedOn(event
				@threejsRootNode.children
				@renderer)
		if (intersects.length > 0)
			intersects[0].object.material.color.set(new THREE.Color(1, 0, 0))

	# voxelises a single model
	voxelise: (optimizedModel, node) =>
		# check if model was already voxelised
		for data in @voxelisedModels
			if data.node.meshHash is node.meshHash
				console.warn 'already voxelised this model'
				return

		@voxeliser ?= new Voxeliser
		if not @lego
			@lego = new BrickSystem( 8, 8, 3.2, 1.7, 2.512)
			@lego.add_BrickTypes [
					[1,1,1],[1,2,1],[1,3,1],[1,4,1],[1,6,1],[1,8,1],[2,2,1],[2,3,1],
					[2,4,1],[2,6,1],[2,8,1],[2,10,1],[1,1,3],[1,2,3],[1,3,3],[1,4,3],
					[1,6,3],[1,8,3],[1,10,3],[1,12,3],[1,16,3],[2,2,3],[2,3,3],[2,4,3],
					[2,6,3],[2,8,3],[2,10,3]
				]

		grid = @voxeliser.voxelise(optimizedModel, @lego)

		voxelisedData = new VoxeliserData(node, grid, voxelRenderer grid, null, null)
		@voxelisedModels.push voxelisedData
		@threejsRootNode.add voxelisedData.gridForThree

	layout: (voxelizedModel) ->
		if voxelizedModel.layout
			console.warn 'Model is already layouted'
			return

		legoLayout = new BrickLayout(voxelizedModel.grid)
		layouter = new BrickLayouter(legoLayout)
		layouter.layoutAll()
		legoMesh = legoLayout.get_SceneModel()
		voxelizedModel.addLayout(legoLayout, legoMesh)

		@threejsRootNode.remove voxelizedModel.gridForThree
		@threejsRootNode.add voxelizedModel.layoutForThree

# Helper Class that - after voxelising and layouting -
# contains the voxelised grid, it's ThreeJS representation
# and the ThreeJs
class VoxeliserData
	constructor: (@node, @grid, @gridForThree,
	        @layout = null, @layoutForThree = null) ->
	    return
	addLayout: (@layout, @layoutForThree) => return
