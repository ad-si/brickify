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
		###
		properties:
			gridDeltaX:
				description: 'Voxelgrid dx'
				type: 'number'
			gridDeltaY:
				description: 'Voxelgrid dy'
				type: 'number'
			gridDeltaZ:
				description: 'Voxelgrid dz'
				type: 'number'
		###
		}

	uiEnabled: (node) ->
		@currentNode = node

	uiDisabled: (node) ->
		@currentNode = null

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

		threenode = @getThreeRootForNode selectedNode
		@voxelVisualizer.clear(threenode)

		results = @pipeline.run optimizedModel,
			{debugVoxel: @debugVoxel}, true
		grid = results.lastResult

		@voxelVisualizer.createVisibleVoxel grid, threenode

	getThreeRootForNode: (selectedNode) =>
		id = selectedNode.pluginData.solidRenderer.threeObjectUuid
		if @threeObjects[id]?
			return @threeObjects[id]
		else
			tn = new THREE.Object3D()
			@threeObjects[id] = tn
			@threejsRootNode.add tn
			return tn




