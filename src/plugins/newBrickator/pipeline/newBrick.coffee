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

	# returns a set of all bricks that are next to this brick
	# in the given direction
	getNeighbors: (direction) =>
		neighbors = new Set()

		@forEachVoxel (voxel) ->
			neighborBrick = voxel.neighbors[direction].brick
			neighbors.add neighborBrick if neighborBrick? and neighborBrick != @

		return neighbors

	# Splits up this brick in 1x1x1 bricks and returns them as a set
	splitUp: =>
		newBricks = new Set()

		@forEachVoxel (voxel) ->
			newBricks.add new Brick([voxel])

		return newBricks

	# removes all references to this brick from voxels
	# this brick has to be deleted after that
	clear: =>
		@forEachVoxel (voxel) ->
			voxel.brick = false

		@voxels.clear()

	# merges this brick with the other brick specified,
	# the other brick gets deleted in the process
	mergeWith: (otherBrick) =>
		newVoxels = new Set()

		otherBrick.forEachVoxel (voxel) =>
			newVoxels.add voxel

		otherBrick.clear()

		newVoxels.forEach (voxel) =>
			voxel.brick = @
			@voxels.add voxel

module.exports = Brick
