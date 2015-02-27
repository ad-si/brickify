Brick = require './Brick'
arrayHelper = require './arrayHelper'

module.exports = class BrickGraph
	# Brick graph can be created either with a grid,
	# or with a pre-filled list of bricks
	constructor: (@grid, brickList) ->
		if not brickList?
			@bricks = []
			Brick.nextBrickIndex = 0
			@_initialize()
		else
			@bricks = brickList

	# creates a brickList that creates a 1x1 brick for each
	# enabled voxel in the grid
	# the @bricks list is an array consisting of an array for each z-layer,
	# within a z-layer, the array is an unordered list of Bricks
	# that belong to this z-layer
	_initialize: () =>
		for z in [0..@grid.numVoxelsZ - 1] by 1
			@bricks[z] = []

		# create all bricks
		for z in [0..@grid.numVoxelsZ - 1] by 1
			for x in [0..@grid.numVoxelsX - 1] by 1
				for y in [0..@grid.numVoxelsY - 1] by 1

					if @grid.zLayers[z]?[x]?[y]?
						if @_testVoxelExistsAndEnabled z, x, y

							# create brick
							position = {x: x, y: y, z: z}
							size = {x: 1,y: 1,z: 1}
							brick = new Brick position, size
							#brick.id = @nextBrickIdx()
							@grid.zLayers[z][x][y].brick = brick

							@_connectToBrickBelow brick, x,y,z
							@_connectToBrickXm brick, x,y,z
							@_connectToBrickYm brick, x,y,z

							@bricks[z].push brick

		# remove references to bricks that will later become invalid
		for z in [0..@grid.numVoxelsZ - 1] by 1
			for x in [0..@grid.numVoxelsX - 1] by 1
				for y in [0..@grid.numVoxelsY - 1] by 1
					if @grid.zLayers[z]?[x]?[y]?
						delete @grid.zLayers[z][x][y].brick

	_testVoxelExistsAndEnabled: (z, x, y) =>
		if (@grid.zLayers[z][x][y] == false)
			return false
		return @grid.zLayers[z][x][y].enabled == true

	_connectToBrickBelow: (brick, x, y, z) =>
		if z > 0 and @grid.zLayers[z - 1]?[x]?[y]? and
		@_testVoxelExistsAndEnabled z - 1, x, y
			brickBelow = @grid.zLayers[z - 1][x][y].brick
			brick.lowerSlots[0][0] = brickBelow
			brickBelow.upperSlots[0][0] = brick
		return

	_connectToBrickXm: (brick, x, y, z) =>
		if x > 0 and @grid.zLayers[z]?[x - 1]?[y]? and
		@_testVoxelExistsAndEnabled z, x - 1, y
			brick.neighbours[0] = [@grid.zLayers[z][x - 1][y].brick]
			@grid.zLayers[z][x - 1][y].brick.neighbours[1] = [brick]
		return

	_connectToBrickYm: (brick, x, y, z) =>
		if y > 0 and @grid.zLayers[z]?[x]?[y - 1]? and
		@_testVoxelExistsAndEnabled z, x, y - 1
			brick.neighbours[2] = [@grid.zLayers[z][x][y - 1].brick]
			@grid.zLayers[z][x][y - 1].brick.neighbours[3] = [brick]
		return

	# remove the selected brick out of the graph datastructure
	deleteBrick: (brick) =>
		# delete from structure
		arrayHelper.removeFirstOccurenceFromArray brick, @bricks[brick.position.z]
		# remove references to neighbours/connections
		brick.removeSelfFromSurrounding()

	# updates the 'voxel.brick' reference in each voxel in the grid
	updateReferencesInGrid: () =>
		# clear all references
		@grid.forEachVoxel (voxel) ->
			voxel.brick = null

		# set references from brick list
		for layer in @bricks
			for brick in layer
				for x in [brick.position.x..((brick.position.x + brick.size.x) - 1)] by 1
					for y in [brick.position.y..((brick.position.y + brick.size.y) - 1)] by 1
						for z in [brick.position.z..((brick.position.z + brick.size.z) - 1)] by 1
							voxel = @grid.zLayers[z][x][y]
							if voxel?
								voxel.brick = brick
							else
								console.warn "Brick without voxel at #{x},#{y},#{z}"

