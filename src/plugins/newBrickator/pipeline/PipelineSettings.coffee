module.exports = class PipelineSettings
	constructor: (globalConfig) ->
		@gridSpacing = globalConfig.gridSpacing
		@modelTransform = null
		@voxelizing = true
		@initLayout = true
		@layouting = true
		@reLayout = false

	deactivateLayouting: =>
		@initLayout = false
		@layouting = false

	deactivateVoxelizing: =>
		@voxelizing = false

	onlyInitLayout: =>
		@deactivateVoxelizing()
		@deactivateLayouting()
		@reLayout = false
		@initLayout = true

	onlyRelayout: =>
		@deactivateVoxelizing()
		@deactivateLayouting()
		@reLayout = true

	setGridSpacing: (x, y, z) =>
		@gridSpacing.x = x
		@gridSpacing.y = y
		@gridSpacing.z = z

	setModelTransform: (transformMatrix) =>
		@modelTransform = transformMatrix
