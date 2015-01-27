modelCache = require '../../client/modelCache'
LegoPipeline = require './LegoPipeline'
interactionHelper = require '../../client/interactionHelper'
THREE = require 'three'
VoxelVisualizer = require './VoxelVisualizer'
BrickVisualizer = require './BrickVisualizer'
PipelineSettings = require './PipelineSettings'
objectTree = require '../../common/objectTree'
Brick = require './Brick'

module.exports = class NewBrickator
	constructor: () ->
		@pipeline = new LegoPipeline()
	init: (@bundle) => return
	init3d: (@threejsRootNode) => return

	getConvertUiSchema: () =>
		legoCallback = (selectedNode) =>
			@runLegoPipelineOnNode selectedNode

		return {
		title: 'NewBrickator'
		type: 'object'
		actions:
			a1:
				title: 'Legofy'
				callback: legoCallback
		properties:
			gridDeltaX:
				description: 'Voxelgrid dx (0..7)'
				type: 'number'
			gridDeltaY:
				description: 'Voxelgrid dy (0..7)'
				type: 'number'
			gridDeltaZ:
				description: 'Voxelgrid dz (0..3)'
				type: 'number'
		}

	onClick: (event) =>
		intersects =
			interactionHelper.getPolygonClickedOn(event
				@threejsRootNode.children
				@bundle.renderer)
		if (intersects.length > 0)
			obj = intersects[0].object
			###
			@threejsRootNode.remove obj
			###
			obj.material = new THREE.MeshLambertMaterial({
				color: 0xdf004c
				opacity: 0.5
				transparent: true
			})
			console.log "Setting debug voxel to:
			x: #{obj.voxelCoords.x} y: #{obj.voxelCoords.y} z: #{obj.voxelCoords.z}"

			@debugVoxel = obj.voxelCoords

	onStateUpdate: (state) =>
		#delete voxel visualizations for deleted objects
		availableObjects = []
		objectTree.forAllSubnodeProperties state.rootNode,
			'newBrickator',
			(property) ->
				availableObjects.push property.threeObjectUuid

		for child in @threejsRootNode.children
				if availableObjects.indexOf(child.uuid) < 0
					@threejsRootNode.remove @threeObjects[key]

	processFirstObject: () =>
		@bundle.statesync.performStateAction (state) =>
			console.log state
			node = state.rootNode.children[0]
			@runLegoPipelineOnNode node

	runLegoPipelineOnNode: (selectedNode) =>
		modelCache.request(selectedNode.meshHash).then(
			(optimizedModel) =>
				@runLegoPipeline optimizedModel, selectedNode
		)

	getUiSettings: (selectedNode) ->
		if selectedNode.toolsValues?.newbrickator?
			return selectedNode.toolsValues.newbrickator
		else
			if !(selectedNode.toolsValues?)
				selectedNode.toolsValues = {}

			selectedNode.toolsValues.newbrickator = {
				gridDeltaX: 0
				gridDeltaY: 0
				gridDeltaZ: 0
			}
			return selectedNode.toolsValues.newbrickator

	runLegoPipeline: (optimizedModel, selectedNode) =>
		@voxelVisualizer ?= new VoxelVisualizer()

		uiSettings = @getUiSettings selectedNode

		threeNode = @getThreeObjectByNode selectedNode
		@voxelVisualizer.clear(threeNode)
		
		settings = new PipelineSettings()
		settings.setGridOffset uiSettings.gridDeltaX,
			uiSettings.gridDeltaY, uiSettings.gridDeltaZ

		results = @pipeline.run optimizedModel, settings, true
		grid = results.accumulatedResults.grid

		@voxelVisualizer.createVisibleVoxels grid, threeNode, false

		#test dataset (remove with real data if layouter is ready)
		brickTestData = [
			[
				new Brick({x: 0, y: -0}, {x: 1, y: 1})
				new Brick({x: 2, y: -0}, {x: 2, y: 1})
			]
			[]
			[
				new Brick({x: 0, y: -0}, {x: 2, y: 2})
				new Brick({x: 5, y: -0}, {x: 2, y: 4})
			]
		]

		@brickVisualizer ?= new BrickVisualizer()
		@brickVisualizer.createVisibleBricks(
			threeNode, brickTestData, grid
		)
	getThreeObjectByNode: (node) =>
		if node.pluginData.newBrickator?
			uuid = node.pluginData.newBrickator.threeObjectUuid
			for node in @threejsRootNode.children
				return node if node.uuid == uuid
		object = new THREE.Object3D()
		@threejsRootNode.add object
		node.pluginData.newBrickator = {'threeObjectUuid': object.uuid}
		object
