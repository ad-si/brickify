class Brick
	@direction = {
		Xp: 'Xp'
		Xm: 'Xm'
		Yp: 'Yp'
		Ym: 'Ym'
		Zp: 'Zp'
		Zm: 'Zm'
	}

	@validBrickSizes = [
		[1, 1, 1], [1, 2, 1], [1, 3, 1], [1, 4, 1], [1, 6, 1], [1, 8, 1],
		[2, 2, 1], [2, 3, 1], [2, 4, 1], [2, 6, 1], [2, 8, 1], [2, 10, 1],
		[1, 1, 3], [1, 2, 3], [1, 3, 3], [1, 4, 3],
		[1, 6, 3], [1, 8, 3], [1, 10, 3], [1, 12, 3], [1, 16, 3]
		[2, 2, 3], [2, 3, 3], [2, 4, 3], [2, 6, 3], [2, 8, 3], [2, 10, 3]
	]

	# returns true if the given size is a valid size
	@isValidSize: (x, y, z) =>
		for testSize in Brick.validBrickSizes
			if testSize[0] == x and testSize[1] == y and
			testSize[2] == z
				return true
		return false

	# Creates a brick out of the given set of voxels
	# Takes ownership of voxels without further processing
	constructor: (arrayOfVoxels) ->
		@voxels = new Set()
		for voxel in arrayOfVoxels
			voxel.brick = @
			@voxels.add voxel

	# enumerates over each voxel that belongs to this brick
	forEachVoxel: (callback) =>
		@voxels.forEach callback

	# returns the voxel the brick consists of, if it consists out
	# of one voxel. else returns null
	getVoxel: =>
		if @voxels.size > 1
			return null
		iterator = @voxels.entries()
		return iterator.next().value[0]

	# Returns true if a voxel with this coordinates
	# belongs to this brick
	isVoxelInBrick: (x, y, z) ->
		inBrick = false
		@forEachVoxel (vox) =>
			if vox.position.x == x and
			vox.position.y == y and
			vox.position.z == z
				inBrick = true
		return inBrick

	# returns the {x, y, z} values of the voxel with
	# the smallest x, y and z.
	# To work properly, this function assumes that there
	# are no holes in the brick and the brick is a proper cuboid
	getPosition: =>
		return @_position if @_position?

		# to bring variables to correct scope
		x = undefined
		y = undefined
		z = undefined

		@forEachVoxel (voxel) =>
			x = voxel.position.x if not x?
			x = Math.min voxel.position.x, x
			y = voxel.position.y if not y?
			y = Math.min voxel.position.y, y
			z = voxel.position.z if not z?
			z = Math.min voxel.position.z, z

		@_position = {
			x: x
			y: y
			z: z
		}
		return @_position

	# returns the size of the brick
	getSize: =>
		return @_size if @_size?
		@_size = {}

		@forEachVoxel (voxel) =>
			#init values
			@_size.maxX ?= @_size.minX ?= voxel.position.x
			@_size.maxY ?= @_size.minY ?= voxel.position.y
			@_size.maxZ ?= @_size.minZ ?= voxel.position.z

			@_size.minX = voxel.position.x if @_size.minX > voxel.position.x
			@_size.minY = voxel.position.y if @_size.minY > voxel.position.y
			@_size.minZ = voxel.position.z if @_size.minZ > voxel.position.z

			@_size.maxX = voxel.position.x if @_size.maxX < voxel.position.x
			@_size.maxY = voxel.position.y if @_size.maxY < voxel.position.y
			@_size.maxZ = voxel.position.z if @_size.maxZ < voxel.position.z

		@_size = {
			x: (@_size.maxX - @_size.minX) + 1
			y: (@_size.maxY - @_size.minY) + 1
			z: (@_size.maxZ - @_size.minZ) + 1
		}

		return @_size

	# returns a set of all bricks that are next to this brick
	# in the given direction
	getNeighbors: (direction) =>
		neighbors = new Set()

		@forEachVoxel (voxel) =>
			if voxel.neighbors[direction]?
				neighborBrick = voxel.neighbors[direction].brick
				neighbors.add neighborBrick if neighborBrick and neighborBrick != @

		return neighbors

	# Connected Bricks are neighbors in Zp and Zm direction
	# because they are connected with studs to each other
	connectedBricks: =>
		connectedBricks = new Set()

		@getNeighbors(Brick.direction.Zp).forEach (brick) ->
			connectedBricks.add brick

		@getNeighbors(Brick.direction.Zm).forEach (brick) ->
			connectedBricks.add brick

		return connectedBricks

	# Splits up this brick in 1x1x1 bricks and returns them as a set
	# This brick has no voxels after this operation
	splitUp: =>
		newBricks = new Set()

		@forEachVoxel (voxel) ->
			newBricks.add new Brick([voxel])

		@_clearData()
		return newBricks

	# removes all references to this brick from voxels
	# this brick has to be deleted after that
	clear: =>
		# clear references
		@forEachVoxel (voxel) ->
			voxel.brick = false
		# and stored data
		@_clearData()

	_clearData: =>
		#clear stored data
		@_size = null
		@_position = null
		@voxels.clear()

	# merges this brick with the other brick specified,
	# the other brick gets deleted in the process
	mergeWith: (otherBrick) =>
		#clear size and position (to be recomputed)
		@_size = null
		@_position = null

		#take voxels from other brick
		newVoxels = new Set()

		otherBrick.forEachVoxel (voxel) =>
			newVoxels.add voxel

		otherBrick.clear()

		newVoxels.forEach (voxel) =>
			voxel.brick = @
			@voxels.add voxel

	# returns true if the size of the brick matches one of
	# @validBrickSizes
	hasValidSize: =>
		size = @getSize()
		return Brick.isValidSize(size.x, size.y, size.z)

	# retruns true if the brick has no holes in it,
	# in other words: is a cuboid
	isHoleFree: =>
		voxelCheck  = {}

		p = @getPosition()
		s = @getSize()

		for x in [p.x...(p.x + s.x)]
			for y in [p.y...(p.y + s.y)]
				for z in [p.z...(p.z + s.z)]
					voxelCheck[x + '-' + y + '-' + z] = false

		@forEachVoxel (voxel) =>
			vp = voxel.position
			voxelCheck[vp.x + '-' + vp.y + '-' + vp.z] = true

		for val of voxelCheck
			return false if voxelCheck[val] == false

		return true

	# returns true if the brick is valid
	# a brick is valid when it has voxels, is hole free and
	# has a valid size
	isValid: =>
		return true if @voxels.size > 0 and
		@hasValidSize() and @isHoleFree()

		return false

	getStability: =>
		s = @getSize()
		p = @getPosition()
		cons = @connectedBricks()

		# possible slots top & bottom
		possibleSlots = s.x * s.y * 2

		# how many slots are actually connected?
		usedSlots = 0

		lowerZ = p.z - 1
		upperZ = p.z + s.z

		# test for each possible slot if neighbour bricks have
		# voxels that belog to this slot
		for x in [p.x...(p.x + s.x)]
			for y in [p.y...(p.y + s.y)]
				cons.forEach (brick) =>
					if brick.isVoxelInBrick(x, y, upperZ)
						usedSlots++
					if brick.isVoxelInBrick(x, y, lowerZ)
						usedSlots++

		return usedSlots / possibleSlots

module.exports = Brick
