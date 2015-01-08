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

	mapWorldToGridRelative: (point) ->
		#maps world coordinates to aligned grid coordinates
		return {
			x: point.x - @origin.x
			y: point.y - @origin.y
			z: point.z - @origin.z
		}

	setRelative: (x,y,z) ->
		# transforms relative (-> mapWorldToGridRelative) coordinates in voxel
		# indices and sets the resulting voxel to true
		x = Math.round(x / @spacing.x)
		y = Math.round(y / @spacing.y)
		z = Math.round(z / @spacing.z)

		if not @zLayers[z]
			@zLayers[z] = []
		if not @zLayers[z][x]
			@zLayers[z][x] = []
		@zLayers[z][x][y] = true
