modelCache = require '../../client/modelCache'
Voxelizer  = require './Voxelizer'

module.exports = class NewBrickator
	constructor: () ->
		# smallest lego brick
		@baseBrick = {
			length: 8
			width: 8
			height: 3.2
		}

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
		}

	voxelize: (optimizedModel, selectedNode) =>
		@voxelizer ?= new Voxelizer(@baseBrick)
		@voxelizer.voxelize optimizedModel
		@voxelizer.createVisibleVoxels @threejsRootNode








