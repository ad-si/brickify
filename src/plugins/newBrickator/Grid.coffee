module.exports = class Grid
	constructor: (baseBrick = {length: 0, width: 0, height: 0}) ->
		@origin = {x: 0, y: 0, z: 0}
		@spacing = {x: baseBrick.length, y: baseBrick.width, z: baseBrick.height}
		@numVoxelsX = 0
		@numVoxelsY = 0
		@numVoxelsZ = 0
		@zLayers = []

	setUpForModel: (optimizedModel) =>
		bb = optimizedModel.boundingBox()
		@origin = bb.min

		@numVoxelsX = Math.ceil (bb.max.x - bb.min.x) / @spacing.x
		@numVoxelsX++

		@numVoxelsY = Math.ceil (bb.max.y - bb.min.y) / @spacing.y
		@numVoxelsY++

		@numVoxelsZ = Math.ceil (bb.max.z - bb.min.z) / @spacing.z
		@numVoxelsZ++

	mapWorldToGridRelative: (point) =>
		# maps world coordinates to aligned grid coordinates
		return {
			x: point.x - @origin.x
			y: point.y - @origin.y
			z: point.z - @origin.z
		}

	mapGridRelativeToVoxel: (point) =>
		# maps aligned grid coordinates to voxel indices
		return {
			x: Math.round(point.x / @spacing.x)
			y: Math.round(point.y / @spacing.y)
			z: Math.round(point.z / @spacing.z)
		}

	mapVoxelToGridRelative: (point) =>
		# maps voxel indices to aligned grid coordinates
		return {
			x: point.x * @spacing.x
			y: point.y * @spacing.y
			z: point.z * @spacing.z
		}

	setVoxel: (voxel, data = true) =>
		# sets the voxel with the given indices to true
		# the voxel may also contain data.
		if not @zLayers[voxel.z]
			@zLayers[voxel.z] = []
		if not @zLayers[voxel.z][voxel.x]
			@zLayers[voxel.z][voxel.x] = []

		if not @zLayers[voxel.z][voxel.x][voxel.y]?
			@zLayers[voxel.z][voxel.x][voxel.y] = {dataEntrys: [data]}
		else
			#if the voxel already exists, push new data to existing array
			@zLayers[voxel.z][voxel.x][voxel.y].dataEntrys.push data

