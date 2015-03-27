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
	_initialize: =>
		for z in [0..@grid.numVoxelsZ - 1] by 1
			@bricks[z] = []

		# create all bricks
		for z in [0...@grid.numVoxelsZ] by 1
			for x in [0...@grid.numVoxelsX] by 1
				for y in [0...@grid.numVoxelsY] by 1
					voxel = @grid.getVoxel x, y, z
					if voxel?.enabled
						# create brick
						position = voxel.position
						size = {x: 1,y: 1,z: 1}

						brick = new Brick position, size
						voxel.brick = brick

						@_connectToBrickBelow brick, position.x, position.y, position.z
						@_connectToBrickXm brick, position.x, position.y, position.z
						@_connectToBrickYm brick, position.x, position.y, position.z

						@bricks[position.z].push brick

		# remove references to bricks that will later become invalid
		@grid.forEachVoxel (voxel) ->
			delete voxel.brick

	_voxelExistsAndIsEnabled: (x, y, z) =>
		# !! makes sure a boolean is returned
		return !!@grid.getVoxel(x, y, z)?.enabled

	_connectToBrickBelow: (brick, x, y, z) =>
		return if not @_voxelExistsAndIsEnabled x, y, z - 1

		brickBelow = @grid.getVoxel(x, y, z - 1).brick
		brick.lowerSlots[0][0] = brickBelow
		brickBelow.upperSlots[0][0] = brick

	_connectToBrickXm: (brick, x, y, z) =>
		return if not @_voxelExistsAndIsEnabled x - 1, y, z
		voxel = @grid.getVoxel(x - 1, y, z)

		brick.neighbors[Brick.direction.Xm] = [voxel.brick]
		voxel.brick.neighbors[Brick.direction.Xp] = [brick]

	_connectToBrickYm: (brick, x, y, z) =>
		return if not @_voxelExistsAndIsEnabled x, y - 1, z
		voxel = @grid.getVoxel(x, y - 1, z)

		brick.neighbors[Brick.direction.Ym] = [voxel.brick]
		voxel.brick.neighbors[Brick.direction.Yp] = [brick]

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

		# add neighbor references
		neighborXp = @getBrickAt x + 1, y, z
		neighborXm = @getBrickAt x - 1, y, z
		neighborYp = @getBrickAt x, y + 1, z
		neighborYm = @getBrickAt x, y - 1, z

		#x-
		if neighborXm?
			brick.neighbors[Brick.direction.Xm].push neighborXm
			neighborXm.neighbors[Brick.direction.Xp].push brick

		#x+
		if neighborXp?
			brick.neighbors[Brick.direction.Xp].push neighborXp
			neighborXp.neighbors[Brick.direction.Xm].push brick

		#y-
		if neighborYm?
			brick.neighbors[Brick.direction.Ym].push neighborYm
			neighborYm.neighbors[Brick.direction.Yp].push brick

		#y+
		if neighborYp?
			brick.neighbors[Brick.direction.Yp].push neighborYp
			neighborYp.neighbors[Brick.direction.Ym].push brick

		# add upper / lower slots
		upperBrick = @getBrickAt x, y, z + 1
		if upperBrick?
			slot = {
				x: brick.position.x - upperBrick.position.x
				y: brick.position.y - upperBrick.position.y
			}
			upperBrick.lowerSlots[slot.x][slot.y] = brick
			brick.upperSlots[0][0] = upperBrick

		lowerBrick = @getBrickAt x, y, z - 1
		if lowerBrick?
			slot = {
				x: brick.position.x - lowerBrick.position.x
				y: brick.position.y - lowerBrick.position.y
			}
			lowerBrick.upperSlots[slot.x][slot.y] = brick
			brick.lowerSlots[0][0] = lowerBrick

		# add to list
		@bricks[z].push brick

		return brick

	# remove the selected brick from the graph datastructure
	deleteBrick: (brick) =>
		# delete from structure
		arrayHelper.removeFirstOccurenceFromArray brick, @bricks[brick.position.z]
		# remove references to neighbors/connections
		brick.removeSelfFromSurrounding()
		# remove references in voxels
		@forEachVoxelInBrick brick, (voxel) -> voxel.brick = null

	# updates the 'voxel.brick' reference in each voxel in the grid
	updateReferencesInGrid: =>
		# set references from brick list
		@forEachBrick (brick) =>
			@forEachVoxelInBrick brick, (voxel) -> voxel.brick = brick

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
