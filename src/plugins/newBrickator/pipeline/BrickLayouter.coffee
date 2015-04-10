Brick = require './Brick'
BrickGraph = require './BrickGraph'
arrayHelper = require './arrayHelper'

###
# @class BrickLayouter
###

class BrickLayouter
	constructor: (pseudoRandom = false) ->
		if pseudoRandom
			@seed = 42
			@_random = @_pseudoRandom
		return

	initializeBrickGraph: (grid) ->
		return brickGraph: new BrickGraph(grid)

	# main while loop condition:
	# any brick can still merge --> use heuristic:
	# keep a counter, break if last number of unsuccessful tries > (some number
	# or some % of total bricks in object)
	# !! Expects bricks to layout to be a Set !!
	layoutByGreedyMerge: (brickGraph, bricksToLayout) =>
		numRandomChoices = 0
		numRandomChoicesWithoutMerge = 0
		numTotalInitialBricks = 0

		if not bricksToLayout?
			bricksToLayout = brickGraph.getAllBricks()

		numTotalInitialBricks += bricksToLayout.size
		maxNumRandomChoicesWithoutMerge = numTotalInitialBricks

		return unless numTotalInitialBricks > 0

		loop
			brick = @_chooseRandomBrick bricksToLayout
			if !brick?
				return {brickGraph: brickGraph}

			numRandomChoices++
			mergeableNeighbors = @_findMergeableNeighbors brick

			if !@_anyDefinedInArray(mergeableNeighbors)
				numRandomChoicesWithoutMerge++
				if numRandomChoicesWithoutMerge >= maxNumRandomChoicesWithoutMerge
					console.log " - randomChoices #{numRandomChoices}
											withoutMerge #{numRandomChoicesWithoutMerge}"
					break # done with initial layout
				else
					continue # randomly choose a new brick

			while(@_anyDefinedInArray(mergeableNeighbors))
				mergeIndex = @_chooseNeighborsToMergeWith mergeableNeighbors
				neighborsToMergeWith = mergeableNeighbors[mergeIndex]

				@_mergeBricksAndUpdateGraphConnections brick,
					neighborsToMergeWith, bricksToLayout
				mergeableNeighbors = @_findMergeableNeighbors brick

		return {brickGraph: brickGraph}

	###
	# Split up all supplied bricks into single bricks and relayout locally. This
	# means that all supplied bricks and their neighbors will be relayouted.
	#
	# @param {Array<Brick>} bricks bricks that should be split
	###
	splitBricksAndRelayoutLocally: (bricks, grid, brickGraph) =>
		bricksToSplit = new Set()

		for brick in bricks
			# add this brick to be splitted
			bricksToSplit.add brick

			# get neighbours in same z layer
			xp = brick.getNeighbors(Brick.direction.Xp)
			xm = brick.getNeighbors(Brick.direction.Xm)
			yp = brick.getNeighbors(Brick.direction.Yp)
			ym = brick.getNeighbors(Brick.direction.Ym)

			# add them all to be splitted as well
			xp.forEach (brick) -> bricksToSplit.add brick
			xm.forEach (brick) -> bricksToSplit.add brick
			yp.forEach (brick) -> bricksToSplit.add brick
			ym.forEach (brick) -> bricksToSplit.add brick

		newBricks = @_splitBricks bricksToSplit

		bricksToBeDeleted = []
		newBricks.forEach (brick) ->
			voxel = brick.getVoxel()

			# delete bricks where voxels are disabled (3d printed)
			if not voxel.enabled
				bricksToBeDeleted.push voxel

		for brick in bricksToBeDeleted
			newBricks.delete brick

		@layoutByGreedyMerge brickGraph, newBricks

		return {
			removedBricks: bricksToSplit
			newBricks: newBricks
		}

	# splits each brick in bricks to split, returns all newly generated
	# bricks as a set
	_splitBricks: (bricksToSplit) ->
		newBricks = new Set()

		bricksToSplit.forEach (brick) ->
			splitGenerated = brick.splitUp()
			splitGenerated.forEach (brick) ->
				newBricks.add brick

		return newBricks

	_anyDefinedInArray: (mergeableNeighbors) ->
		return mergeableNeighbors.some (entry) -> entry?

	# choses a random brick out of the set
	_chooseRandomBrick: (setOfBricks) =>
		if setOfBricks.size == 0
			return null

		rnd = @_random(setOfBricks.size)

		iterator = setOfBricks.entries()
		brick = iterator.next().value[0]
		while rnd > 0
			brick = iterator.next().value[0]
			rnd--

		return brick

	_random: (max) ->
		Math.floor Math.random() * max

	_pseudoRandom: (max) ->
		@seed = (1103515245 * @seed + 12345) % 2 ^ 31
		@seed % max

	# Searches for mergeable neighbours in [x-, x+, y-, y+] direction
	# and returns an array out of arrays of IDs for each direction
	_findMergeableNeighbors: (brick) =>
		mergeableNeighbors = []

		mergeableNeighbors.push @_findMergeableNeighborsInDirection(
			brick
			Brick.direction.Xm
			(obj) -> return obj.y
			(obj) -> return obj.x
		)
		mergeableNeighbors.push @_findMergeableNeighborsInDirection(
			brick
			Brick.direction.Xp
			(obj) -> return obj.y
			(obj) -> return obj.x
		)
		mergeableNeighbors.push @_findMergeableNeighborsInDirection(
			brick
			Brick.direction.Ym
			(obj) -> return obj.x
			(obj) -> return obj.y
		)
		mergeableNeighbors.push @_findMergeableNeighborsInDirection(
			brick
			Brick.direction.Yp
			(obj) -> return obj.x
			(obj) -> return obj.y
		)

		return mergeableNeighbors

	###
	# Checks if brick can merge in the direction specified.
	#
	# @param {Brick} brick the brick whose neighbors to check
	# @param {Number} dir the merge direction as specified in Brick.direction
	# @param {Function} widthFn the function to determine the brick's width
	# @param {Function} lengthFn the function to determine the brick's height
	# @return {Array<Brick>} Bricks in the merge direction if this brick can merge
	# in this dir undefined otherwise.
	# @see Brick
	###
	_findMergeableNeighborsInDirection: (brick, dir, widthFn, lengthFn) ->
		neighborsInDirection = brick.getNeighbors(dir)
		if neighborsInDirection.size > 0
			# check that the neighbors together dont exceed this bricks width
			width = 0
			neighborsInDirection.forEach (neighbor) ->
				width += widthFn neighbor.getSize()

			# if they have the same width, check ...?
			if width == widthFn(brick.getSize())
				minWidth = widthFn brick.getPosition()

				maxWidth = widthFn(brick.getPosition())
				maxWidth += widthFn(brick.getSize()) - 1

				length = null

				neighborsInDirection.forEach (neighbor) ->
					length ?= lengthFn neighbor.getSize()

					if widthFn(neighbor.getPosition()) < minWidth
						return null

					nw = widthFn(neighbor.getPosition()) + widthFn(neighbor.getSize()) - 1
					if nw > maxWidth
						return null

					if lengthFn(neighbor.getSize()) != length
						return null

				if Brick.isValidSize(widthFn(brick.getSize()), lengthFn(brick.getSize()) +
				length, brick.getSize().z)
					return neighborsInDirection

	# Returns the index of the mergeableNeighbors sub-set-in-this-array,
	# where the bricks have the most connected neighbors.
	# If multiple sub-arrays have the same number of connected neigbours,
	# one is randomly chosen
	_chooseNeighborsToMergeWith: (mergeableNeighbors) =>
		numConnections = []
		maxConnections = 0

		for neighborSet, i in mergeableNeighbors
			continue if not neighborSet?

			connectedBricks = new Set()

			neighborSet.forEach (neighbor) ->
				neighborConnections = neighbor.connectedBricks()
				neighborConnections.forEach (brick) ->
					connectedBricks.add brick

			numConnections.push {
				num: connectedBricks.size
				index: i
			}

			maxConnections = Math.max maxConnections, connectedBricks.size

		largestConnections = numConnections.filter (element) ->
			return element.num == maxConnections

		randomOfLargest = largestConnections[@_random(largestConnections.length)]
		return randomOfLargest.index

	_mergeBricksAndUpdateGraphConnections: (
		brick, mergeNeighbors, bricksToLayout ) ->

		mergeNeighbors.forEach (neighborToMergeWith) ->
			bricksToLayout.delete neighborToMergeWith
			brick.mergeWith neighborToMergeWith

		return brick

module.exports = BrickLayouter
