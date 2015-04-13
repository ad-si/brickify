Brick = require './Brick'
arrayHelper = require './arrayHelper'

module.exports = class BrickGraph
	constructor: (@grid) ->
		@_initialize()

	# create a 1x1x1 brick (out of each voxel)
	# (overrides existing bricks)
	_initialize: =>
		@grid.forEachVoxel (voxel) ->
			new Brick([voxel])

	# returns all bricks as a set
	getAllBricks: =>
		bricks = new Set()

		@grid.forEachVoxel (voxel) ->
			if voxel.brick
				bricks.add voxel.brick

		return bricks
