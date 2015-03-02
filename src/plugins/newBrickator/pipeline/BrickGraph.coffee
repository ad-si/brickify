Brick = require './Brick'
arrayHelper = require './arrayHelper'

module.exports = class BrickGraph
	# Brick graph can be created either with a grid,
	# or with a pre-filled list of bricks
	constructor: (@grid, brickList) ->
		if not brickList?
			@bricks = []
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
						if @_voxelExistsAndIsEnabled z, x, y

							# create brick
							position = {x: x, y: y, z: z}
							size = {x: 1,y: 1,z: 1}
							brick = new Brick position, size
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

	_voxelExistsAndIsEnabled: (z, x, y) =>
		return !!@grid.zLayers[z]?[x]?[y]?.enabled

	_connectToBrickBelow: (brick, x, y, z) =>
		return if not @_voxelExistsAndIsEnabled z - 1, x, y
		
		brickBelow = @grid.zLayers[z - 1][x][y].brick
		brick.lowerSlots[0][0] = brickBelow
		brickBelow.upperSlots[0][0] = brick

	_connectToBrickXm: (brick, x, y, z) =>
		return if not @_voxelExistsAndIsEnabled z, x - 1, y

		brick.neighbours[Brick.direction.Xm] = [@grid.zLayers[z][x - 1][y].brick]
		@grid.zLayers[z][x - 1][y].brick.neighbours[Brick.direction.Xp] = [brick]

	_connectToBrickYm: (brick, x, y, z) =>
		return if not @_voxelExistsAndIsEnabled z, x, y - 1
		
		brick.neighbours[Brick.direction.Ym] = [@grid.zLayers[z][x][y - 1].brick]
		@grid.zLayers[z][x][y - 1].brick.neighbours[Brick.direction.Yp] = [brick]

	forEachBrick: (callback) =>
		for layer in @bricks
			for brick in layer
				callback(brick)

	getBrickAt: (x, y, z) ->
		layer = @bricks[z]
		return null if not layer?

		for brick in layer
			if x >= brick.position.x and x < (brick.position.x + brick.size.x)
				if y >= brick.position.y and y < (brick.position.y + brick.size.y)
					return brick

	# creates a 1x1 brick at the given position. warning: does not check
	# if a brick already exists there
	createBrick: (x, y, z) =>
		brick = new Brick {x: x, y: y, z: z}, {x: 1, y: 1}

		# add neighbour references
		neighbourXp = @getBrickAt x + 1, y, z
		neighbourXm = @getBrickAt x - 1, y, z
		neighbourYp = @getBrickAt x, y + 1, z
		neighbourYm = @getBrickAt x, y - 1, z

		#x-
		if neighbourXm?
			brick.neighbours[Brick.direction.Xm].push neighbourXm
			neighbourXm.neighbours[Brick.direction.Xp].push brick

		#x+
		if neighbourXp?
			brick.neighbours[Brick.direction.Xp].push neighbourXp
			neighbourXp.neighbours[Brick.direction.Xm].push brick

		#y-
		if neighbourYm?
			brick.neighbours[Brick.direction.Ym].push neighbourYm
			neighbourYm.neighbours[Brick.direction.Yp].push brick

		#y+
		if neighbourYp?
			brick.neighbours[Brick.direction.Yp].push neighbourYp
			neighbourYp.neighbours[Brick.direction.Ym].push brick

		# add upper / lower slots
		upperBrick = @getBrickAt x, y, z + 1
		if upperBrick?
			slot = {
				x: brick.position.x - upperBrick.position.x
				y: brick.position.y - upperBrick.position.y
			}
			upperBrick.lowerSlots[slot.x][slot.y] = brick

		lowerBrick = @getBrickAt x, y, z - 1
		if lowerBrick?
			slot = {
				x: brick.position.x - lowerBrick.position.x
				y: brick.position.y - lowerBrick.position.y
			}
			lowerBrick.upperSlots[slot.x][slot.y] = brick

		# add to list
		@bricks[z].push brick

		return brick

	# remove the selected brick from the graph datastructure
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

		forEachVoxelInBrick = (brick, callback) =>
			for x in [brick.position.x..((brick.position.x + brick.size.x) - 1)] by 1
				for y in [brick.position.y..((brick.position.y + brick.size.y) - 1)] by 1
					for z in [brick.position.z..((brick.position.z + brick.size.z) - 1)] by 1
						voxel = @grid.zLayers[z][x][y]
						if voxel?
							callback(voxel)
						else
							console.warn "Brick without voxel at #{x}, #{y}, #{z}"

		# set references from brick list
		@forEachBrick (brick) =>
			forEachVoxelInBrick brick, (voxel) =>
				voxel.brick = brick
	

