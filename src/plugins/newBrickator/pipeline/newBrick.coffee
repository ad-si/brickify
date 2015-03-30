class Brick
	@direction = {
		Xp: 'Xp'
		Xm: 'Xm'
		Yp: 'Yp'
		Ym: 'Ym'
		Zp: 'Zp'
		Zm: 'Zm'
	}

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
			@_size.minY = voxel.position.x if @_size.minY > voxel.position.y
			@_size.minZ = voxel.position.x if @_size.minZ > voxel.position.z

			@_size.maxX = voxel.position.x if @_size.maxX < voxel.position.x
			@_size.maxY = voxel.position.x if @_size.maxY < voxel.position.y
			@_size.maxZ = voxel.position.x if @_size.maxZ < voxel.position.z

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

		@forEachVoxel (voxel) ->
			neighborBrick = voxel.neighbors[direction].brick
			neighbors.add neighborBrick if neighborBrick? and neighborBrick != @

		return neighbors

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
		@voxels.clear()

	# merges this brick with the other brick specified,
	# the other brick gets deleted in the process
	mergeWith: (otherBrick) =>
		#clear size (to be recomputed)
		@_size = null

		#take voxels from other brick
		newVoxels = new Set()

		otherBrick.forEachVoxel (voxel) =>
			newVoxels.add voxel

		otherBrick.clear()

		newVoxels.forEach (voxel) =>
			voxel.brick = @
			@voxels.add voxel

module.exports = Brick
