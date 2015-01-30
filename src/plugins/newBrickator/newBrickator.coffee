modelCache = require '../../client/modelCache'
LegoPipeline = require './LegoPipeline'
interactionHelper = require '../../client/interactionHelper'
THREE = require 'three'
VoxelVisualizer = require './VoxelVisualizer'
BrickVisualizer = require './BrickVisualizer'
PipelineSettings = require './PipelineSettings'
objectTree = require '../../common/objectTree'
Brick = require './Brick'
BrickLayouter = require './BrickLayouter'

module.exports = class NewBrickator
	constructor: () ->
		@pipeline = new LegoPipeline()
		@brickLayouter = new BrickLayouter()

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

	runLegoPipeline: (optimizedModel, selectedNode) =>
		@voxelVisualizer ?= new VoxelVisualizer()

		threeNode = @getThreeObjectByNode selectedNode
		@voxelVisualizer.clear(threeNode)
		
		settings = new PipelineSettings()

		if @debugVoxel?
			settings.setDebugVoxel @debugVoxel.x, @debugVoxel.y, @debugVoxel.z

		results = @pipeline.run optimizedModel, settings, true

		#@voxelVisualizer.createVisibleVoxels(
		#	results.accumulatedResults.grid
		#	threeNode
		#	false
		#	)

		@brickVisualizer ?= new BrickVisualizer()
		@brickVisualizer.createVisibleBricks(
			threeNode,
			results.accumulatedResults.bricks,
			results.accumulatedResults.grid
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
