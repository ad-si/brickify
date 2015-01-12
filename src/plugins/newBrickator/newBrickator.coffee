modelCache = require '../../client/modelCache'
LegoPipeline = require './LegoPipeline'
interactionHelper = require '../../client/interactionHelper'
THREE = require 'three'
VoxelVisualizer = require './VoxelVisualizer'

module.exports = class NewBrickator
	constructor: () ->
		# smallest lego brick
		@baseBrick = {
			length: 8
			width: 8
			height: 3.2
		}
		# default voxel resolution
		@voxelResolution = 1
		@pipeline = new LegoPipeline(@baseBrick)

	init: (@bundle) => return
	init3d: (@threejsRootNode) => return

	getUiSchema: () =>
		voxelCallback1 = (selectedNode) =>
			modelCache.request(selectedNode.meshHash).then(
				(optimizedModel) =>
					@voxelResolution = 1
					@voxelize optimizedModel, selectedNode
			)
		voxelCallback2 = (selectedNode) =>
			modelCache.request(selectedNode.meshHash).then(
				(optimizedModel) =>
					@voxelResolution = 2
					@voxelize optimizedModel, selectedNode
			)
		voxelCallback4 = (selectedNode) =>
			modelCache.request(selectedNode.meshHash).then(
				(optimizedModel) =>
					@voxelResolution = 4
					@voxelize optimizedModel, selectedNode
			)
		voxelCallback8 = (selectedNode) =>
			modelCache.request(selectedNode.meshHash).then(
				(optimizedModel) =>
					@voxelResolution = 8
					@voxelize optimizedModel, selectedNode
			)
		voxelCallback16 = (selectedNode) =>
			modelCache.request(selectedNode.meshHash).then(
				(optimizedModel) =>
					@voxelResolution = 16
					@voxelize optimizedModel, selectedNode
			)
		voxelCallback64 = (selectedNode) =>
			modelCache.request(selectedNode.meshHash).then(
				(optimizedModel) =>
					@voxelResolution = 64
					@voxelize optimizedModel, selectedNode
			)

		return {
		title: 'NewBrickator'
		type: 'object'
		actions:
			a1:
				title: 'Voxelize r=1'
				callback: voxelCallback1
			a2:
				title: 'Voxelize r=2'
				callback: voxelCallback2
			a4:
				title: 'Voxelize r=4'
				callback: voxelCallback4
			a8:
				title: 'Voxelize r=8'
				callback: voxelCallback8
			a16:
				title: 'Voxelize r=16'
				callback: voxelCallback16
			a64:
				title: 'Voxelize r=64'
				callback: voxelCallback64
		}

	uiEnabled: (node) ->
		@currentNode = node

	uiDisabled: (node) ->
		@currentNode = null

	onStateUpdate: (state) =>
		return

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

	voxelize: (optimizedModel, selectedNode) =>
		@voxelVisualizer ?= new VoxelVisualizer(@threejsRootNode)

		@voxelVisualizer.clear()
		results = @pipeline.run optimizedModel,
			{voxelResolution: @voxelResolution, debugVoxel: @debugVoxel}, true
		grid = results.lastResult
		@voxelVisualizer.createVisibleVoxel grid








