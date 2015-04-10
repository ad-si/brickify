Brick = require './newBrick'
arrayHelper = require './arrayHelper'

module.exports = class BrickGraph
	constructor: (@grid) -> return

	# create a 1x1x1 brick (out of each voxel)
	# (overrides existing bricks)
	_initialize: =>
		@grid.forEachVoxel (voxel) ->
			new Brick([voxel])

	# returns all bricks as an set
	getAllBricks: =>
		bricks = new Set()

		@grid.forEachVoxel (voxel) ->
			if voxel.brick
				bricks.add voxel.brick

		return bricks

	_voxelExistsAndIsEnabled: (x, y, z) =>
		# !! makes sure a boolean is returned
		return !!@grid.getVoxel(x, y, z)?.enabled

	forEachBrick: (callback) =>
		for layer in @bricks
			for brick in layer
				callback(brick)

	forEachVoxelInBrick: (brick, callback) =>
		for x in [brick.position.x..((brick.position.x + brick.size.x) - 1)] by 1
			for y in [brick.position.y..((brick.position.y + brick.size.y) - 1)] by 1
				for z in [brick.position.z..((brick.position.z + brick.size.z) - 1)] by 1
					voxel = @grid?.getVoxel x, y, z
					if voxel?
						callback(voxel)
					else
						console.warn "Brick without voxel at #{x}, #{y}, #{z}"
						#console.warn brick
