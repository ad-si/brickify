modelCache = require '../../client/modelCache'
LegoPipeline = require './LegoPipeline'
interactionHelper = require '../../client/interactionHelper'
THREE = require 'three'
VoxelVisualizer = require './VoxelVisualizer'
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
		@threeObjects = {}

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
		@currentNode = node
		if node.pluginData.newBrickator?
			threeJsNode = getObjectByNode(@threejsRootNode, node)
			threeJsNode?.visible = true

	uiDisabled: (node) ->
		@currentNode = null
		if node.pluginData.newBrickator?
			threeJsNode = getObjectByNode(@threejsRootNode, node)
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
			'solidRenderer',
			(property) ->
				availableObjects.push property.threeObjectUuid

		for own key of @threeObjects
			if not (availableObjects.indexOf(key) >= 0)
				@voxelVisualizer.clear @threeObjects[key]
				@threejsRootNode.remove @threeObjects[key]
				@threeObjects[key] = undefined

	voxelize: (optimizedModel, selectedNode) =>
		@voxelVisualizer ?= new VoxelVisualizer()
		uiSettings = selectedNode.toolsValues.newbrickator

		threenode = getObjectByNode(@threejsRootNode, selectedNode)
		@voxelVisualizer.clear(threenode)

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

		@voxelVisualizer.createVisibleVoxel grid, threenode, false

	getObjectByNode = (threeJsNode, node) ->
		if node.pluginData.newBrickator?
			uuid = node.pluginData.newBrickator.threeObjectId
			for node in threeJsNode.children
				return node if node.uuid == uuid
		object = new THREE.Object3D()
		threeJsNode.add object
		node.pluginData.newBrickator = {'threeObjectId': object.uuid}
		object
