module.exports  = class PipelineSettings
	constructor: ->
		@gridSpacing = {
			x: 8
			y: 8
			z: 3.2
		}
		@debugVoxel = null
		@modelTransform = null
		@voxelizing = true
		@layouting = true

	deactivateLayouting: =>
		@layouting = false

	deactivateVoxelizing: =>
		@voxelizing = false

	setGridSpacing: (x, y, z) =>
		@gridSpacing.x = x
		@gridSpacing.y = y
		@gridSpacing.z = z

	setDebugVoxel: (x, y, z) =>
		@debugVoxel = {
			x: x
			y: y
			z: z
		}

	setModelTransform: (transformMatrix) =>
		@modelTransform = transformMatrix

