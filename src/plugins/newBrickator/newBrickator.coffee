modelCache = require '../../client/modelCache'
LegoPipeline = require './LegoPipeline'
interactionHelper = require '../../client/interactionHelper'
THREE = require 'three'
VoxelVisualizer = require './VoxelVisualizer'
#BrickVisualizer = require './BrickVisualizer'
BrickLayouter = require './BrickLayouter'
objectTree = require '../../common/objectTree'

module.exports = class NewBrickator
	constructor: () ->
		# smallest lego brick
		@baseBrick = {
			length: 8
			width: 8
			height: 3.2
		}
		@pipeline = new LegoPipeline(@baseBrick)
		@brickLayouter = new BrickLayouter()

	init: (@bundle) => return
	init3d: (@threejsRootNode) => return

	getUiSchema: () =>
		voxelCallback = (selectedNode) =>
			modelCache.request(selectedNode.meshHash).then(
				(optimizedModel) =>
					@voxelize optimizedModel, selectedNode
			)

		return {
		title: 'NewBrickator'
		type: 'object'
		actions:
			a1:
				title: 'Voxelize'
				callback: voxelCallback
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

	uiEnabled: (node) ->
		if node.pluginData.newBrickator?
			threeJsNode =  @getThreeObjectByNode node
			threeJsNode?.visible = true

	uiDisabled: (node) ->
		if node.pluginData.newBrickator?
			threeJsNode = @getThreeObjectByNode node
			threeJsNode?.visible = false

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

	voxelize: (optimizedModel, selectedNode) =>
		@voxelVisualizer ?= new VoxelVisualizer()
		uiSettings = selectedNode.toolsValues.newbrickator

		threeNode = @getThreeObjectByNode selectedNode
		@voxelVisualizer.clear(threeNode)

		settings = {
			debugVoxel: @debugVoxel
			gridDelta: {
				x: uiSettings.gridDeltaX
				y: uiSettings.gridDeltaY
				z: uiSettings.gridDeltaZ
			}
		}

		results = @pipeline.run optimizedModel, settings, true
		grid = results.lastResult

		@voxelVisualizer.createVisibleVoxels grid, threeNode, false

		@layoutForGrid grid, threeNode, true

	layoutForGrid: (grid, threeNode, profiling) =>
		bricks = @brickLayouter.layoutForGrid grid, true
		console.log 'here too'
	#@brickVisualizer.createBricks()

	getThreeObjectByNode: (node) =>
		if node.pluginData.newBrickator?
			uuid = node.pluginData.newBrickator.threeObjectUuid
			for node in @threejsRootNode.children
				return node if node.uuid == uuid
		object = new THREE.Object3D()
		@threejsRootNode.add object
		node.pluginData.newBrickator = {'threeObjectUuid': object.uuid}
		object
