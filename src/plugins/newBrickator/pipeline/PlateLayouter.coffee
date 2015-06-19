log = require 'loglevel'

Brick = require './Brick'
Voxel = require './Voxel'
dataHelper = require './dataHelper'
Random = require './Random'


class PlateLayouter
	constructor: (@pseudoRandom = false, @debugMode = false) ->
		Random.usePseudoRandom @pseudoRandom

	# main while loop condition:
	# any brick can still merge --> use heuristic:
	# keep a counter, break if last number of unsuccessful tries > (some number
	# or some % of total bricks in object)
	# !! Expects bricks to layout to be a Set !!
	layoutPlates: (grid, bricksToLayout) =>
		numRandomChoices = 0
		numRandomChoicesWithoutMerge = 0
		numTotalInitialBricks = 0

		if not bricksToLayout?
			bricksToLayout = grid.getAllBricks()
			bricksToLayout.chooseRandomBrick = grid.chooseRandomBrick

		numTotalInitialBricks += bricksToLayout.size
		maxNumRandomChoicesWithoutMerge = numTotalInitialBricks

		return Promise.resolve {grid: grid} unless numTotalInitialBricks > 0

		loop
			brick = @_chooseRandomBrick bricksToLayout
			if !brick?
				return Promise.resolve {grid: grid}

			numRandomChoices++

			if brick.getSize().z == 3
				continue

			merged = @_mergeLoop brick, bricksToLayout

			if not merged
				numRandomChoicesWithoutMerge++
				if numRandomChoicesWithoutMerge >= maxNumRandomChoicesWithoutMerge
					log.debug "\trandomChoices #{numRandomChoices}
											withoutMerge #{numRandomChoicesWithoutMerge}"
					break # done with initial layout
				else
					continue # randomly choose a new brick

		return Promise.resolve {grid: grid}


	_mergeLoop: (brick, bricksToLayout) =>
		merged = false

		mergeableNeighbors = @_findMergeableNeighbors brick

		while(dataHelper.anyDefinedInArray(mergeableNeighbors))
			merged = true
			mergeIndex = @_chooseNeighborsToMergeWith mergeableNeighbors
			neighborsToMergeWith = mergeableNeighbors[mergeIndex]

			@_mergeBricksAndUpdateGraphConnections brick,
				neighborsToMergeWith, bricksToLayout

			if @debugMode and not brick.isValid()
				log.warn 'Invalid brick: ', brick
				log.warn '> Using pseudoRandom:', @pseudoRandom
				log.warn '> current seed:', Random.getSeed()

			mergeableNeighbors = @_findMergeableNeighbors brick

		return merged

	# Searches for mergeable neighbors in [x-, x+, y-, y+] direction
	# and returns an array out of arrays of IDs for each direction
	_findMergeableNeighbors: (brick) =>
		if brick.getSize().z == 3
			return [null, null, null, null]

		mergeableNeighbors = []

		mergeableNeighbors.push @_findMergeableNeighborsInDirection(
			brick
			Brick.direction.Yp
			(obj) -> return obj.x
			(obj) -> return obj.y
		)
		mergeableNeighbors.push @_findMergeableNeighborsInDirection(
			brick
			Brick.direction.Ym
			(obj) -> return obj.x
			(obj) -> return obj.y
		)
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
		return null if neighborsInDirection.size == 0

		# check that the neighbors together don't exceed this brick's width
		width = 0
		noMerge = false

		neighborsInDirection.forEach (neighbor) ->
			neighborSize = neighbor.getSize()
			if neighborSize.z != brick.getSize().z
				noMerge = true
			if neighbor.getPosition().z != brick.getPosition().z
				noMerge = true
			width += widthFn neighborSize
		return null if noMerge

		# if they have the same accumulative width
		# check if they are in the correct positions,
		# i.e. no spacing between neighbors
		return null if width != widthFn(brick.getSize())

		minWidth = widthFn brick.getPosition()

		maxWidth = widthFn(brick.getPosition())
		maxWidth += widthFn(brick.getSize()) - 1

		length = null

		invalidSize = false
		neighborsInDirection.forEach (neighbor) ->
			length ?= lengthFn neighbor.getSize()
			if widthFn(neighbor.getPosition()) < minWidth
				invalidSize = true
			nw = widthFn(neighbor.getPosition()) + widthFn(neighbor.getSize()) - 1
			if nw > maxWidth
				invalidSize = true
			if lengthFn(neighbor.getSize()) != length
				invalidSize = true
		return null if invalidSize

		if Brick.isValidSize(widthFn(brick.getSize()), lengthFn(brick.getSize()) +
				length, brick.getSize().z)
			return neighborsInDirection
		else
			return null



	# Returns the index of the mergeableNeighbors sub-set-in-this-array,
	# where the bricks have the most connected neighbors.
	# If multiple sub-arrays have the same number of connected neighbors,
	# one is randomly chosen
	_chooseNeighborsToMergeWith: (mergeableNeighbors) ->
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

		randomOfLargest = largestConnections[Random.next(largestConnections.length)]
		return randomOfLargest.index

	_mergeBricksAndUpdateGraphConnections: (
		brick, mergeNeighbors, bricksToLayout ) ->

		mergeNeighbors.forEach (neighborToMergeWith) ->
			bricksToLayout.delete neighborToMergeWith
			brick.mergeWith neighborToMergeWith

		return brick


	finalLayoutPass: (grid) =>
		bricksToLayout = grid.getAllBricks()
		finalPassMerges = 0
		bricksToLayout.forEach (brick) =>
			return unless brick?
			merged = @_mergeLoop brick, bricksToLayout
			if merged
				finalPassMerges++

		log.debug '\tFinal pass merged ', finalPassMerges, ' times.'
		return Promise.resolve {grid: grid}

	# chooses a random brick out of the set
	_chooseRandomBrick: (setOfBricks) ->
		if setOfBricks.size == 0
			return null

		if setOfBricks.chooseRandomBrick?
			return setOfBricks.chooseRandomBrick()

		rnd = Random.next(setOfBricks.size)

		iterator = setOfBricks.entries()
		brick = iterator.next().value[0]
		while rnd > 0
			brick = iterator.next().value[0]
			rnd--

		return brick


module.exports = PlateLayouter
