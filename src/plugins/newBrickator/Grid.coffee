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
