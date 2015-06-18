log = require 'loglevel'

Brick = require './Brick'
Voxel = require './Voxel'
dataHelper = require './dataHelper'
Random = require './Random'

###
# @class BrickLayouter
###

class BrickLayouter
	constructor: (@pseudoRandom = false, @debugMode = false) ->
		Random.usePseudoRandom @pseudoRandom

	initializeBrickGraph: (grid) ->
		grid.initializeBricks()
		return Promise.resolve grid

	layout3LBricks: (grid, bricksToLayout) ->
		numRandomChoices = 0
		numRandomChoicesWithoutMerge = 0
		numTotalInitialBricks = 0

		if not bricksToLayout?
			bricksToLayout = grid.getAllBricks()
			bricksToLayout.chooseRandomBrick = grid.chooseRandomBrick

		numTotalInitialBricks += bricksToLayout.size
		maxNumRandomChoicesWithoutMerge = numTotalInitialBricks
		return unless numTotalInitialBricks > 0

		loop
			brick = @_chooseRandomBrick bricksToLayout
			if !brick?
				return Promise.resolve {grid: grid}
			numRandomChoices++

			merged = @_mergeLoop3L brick, bricksToLayout

			if not merged
				numRandomChoicesWithoutMerge++
				if numRandomChoicesWithoutMerge >= maxNumRandomChoicesWithoutMerge
					log.debug "\trandomChoices #{numRandomChoices}
											withoutMerge #{numRandomChoicesWithoutMerge}"
					break # done with 3L layout
				else
					continue # randomly choose a new brick

			# if brick is 1x1x3, 1x2x3 or instable after mergeLoop3L
			# break it into pieces
			# mark new bricks as bad starting point for 3L brick
			if brick.isSize(1, 1, 3) or brick.getStability() == 0 or
			brick.isSize(1, 2, 3)
				newBricks = brick.splitUp()
				bricksToLayout.delete brick
				newBricks.forEach (newBrick) ->
					bricksToLayout.add newBrick

		return Promise.resolve {grid: grid}

	_findMergeableNeighbors3L: (brick) =>
		mergeableNeighbors = []

		if brick.getSize().z == 1
			mergeableNeighbors.push @_findMergeableNeighborsUpOrDownwards(
				brick
				Brick.direction.Zp
			)
			mergeableNeighbors.push @_findMergeableNeighborsUpOrDownwards(
				brick
				Brick.direction.Zm
			)
			return mergeableNeighbors

		mergeableNeighbors.push @_findMergeableNeighborsInDirection3L(
			brick
			Brick.direction.Yp
			(obj) -> return obj.x
			(obj) -> return obj.y
		)
		mergeableNeighbors.push @_findMergeableNeighborsInDirection3L(
			brick
			Brick.direction.Ym
			(obj) -> return obj.x
			(obj) -> return obj.y
		)
		mergeableNeighbors.push @_findMergeableNeighborsInDirection3L(
			brick
			Brick.direction.Xm
			(obj) -> return obj.y
			(obj) -> return obj.x
		)
		mergeableNeighbors.push @_findMergeableNeighborsInDirection3L(
			brick
			Brick.direction.Xp
			(obj) -> return obj.y
			(obj) -> return obj.x
		)


		return mergeableNeighbors

	_findMergeableNeighborsInDirection3L: (brick, dir, widthFn, lengthFn) =>
		voxels = brick.voxels
		mergeVoxels = new Set()
		mergeBricks = new Set()

		if widthFn(brick.getSize()) > 2 and lengthFn(brick.getSize()) >= 2
			return null

		# find neighbor voxels, noMerge if any is empty
		voxelIter = voxels.values()
		while voxel = voxelIter.next().value
			mVoxel = voxel.neighbors[dir]
			return null unless mVoxel?
			mergeVoxels.add mVoxel unless mVoxel.brick is brick

		# find neighbor bricks,
		# noMerge if any not present
		# noMerge if any brick not 1x1x1
		mergeVoxelIter = mergeVoxels.values()
		while mVoxel = mergeVoxelIter.next().value
			mBrick = mVoxel.brick
			return null unless mBrick and mBrick.isSize(1, 1, 1)
			mergeBricks.add mBrick

		allVoxels = dataHelper.union [voxels, mergeVoxels]

		size = Voxel.sizeFromVoxels(allVoxels)
		if Brick.isValidSize(size.x, size.y, size.z)
			# check if at least half of the top and half of the bottom voxels
			# offer connection possibilities; if not, return
			return mergeBricks if @_minFractionOfConnectionsPresent(allVoxels)

		# check another set of voxels in merge direction, starting from mergeVoxels
		# this is necessary for the 2 brick steps of larger bricks
		mergeVoxels2 = new Set()
		mergeVoxelIter = mergeVoxels.values()
		while mVoxel = mergeVoxelIter.next().value
			mVoxel2 = mVoxel.neighbors[dir]
			return null unless mVoxel2?
			mergeVoxels2.add mVoxel2

		mergeVoxel2Iter = mergeVoxels2.values()
		while mVoxel2 = mergeVoxel2Iter.next().value
			mBrick2 = mVoxel2.brick
			return null unless mBrick2 and mBrick2.isSize(1, 1, 1)
			mergeBricks.add mBrick2

		mergeVoxels2.forEach (mVoxel2) ->
			allVoxels.add mVoxel2

		size = Voxel.sizeFromVoxels(allVoxels)
		if Brick.isValidSize(size.x, size.y, size.z)
			# check if at least half of the top and half of the bottom voxels
			# offer connection possibilities; if not, return
			return mergeBricks if @_minFractionOfConnectionsPresent(allVoxels)


		return null

	_minFractionOfConnectionsPresent: (voxels) =>
		minFraction = .51
		fraction = Voxel.fractionOfConnections voxels
		return fraction >= minFraction

	_mergeLoop3L: (brick, bricksToLayout) =>
		merged = false

		mergeableNeighbors = @_findMergeableNeighbors3L brick

		while(dataHelper.anyDefinedInArray(mergeableNeighbors))
			merged = true
			mergeIndex = @_chooseNeighborsToMergeWith3L mergeableNeighbors
			neighborsToMergeWith = mergeableNeighbors[mergeIndex]

			@_mergeBricksAndUpdateGraphConnections brick,
				neighborsToMergeWith, bricksToLayout

			if @debugMode and not brick.isValid()
				log.warn 'Invalid brick: ', brick
				log.warn '> Using pseudoRandom:', @pseudoRandom
				log.warn '> current seed:', Random.getSeed()

			mergeableNeighbors = @_findMergeableNeighbors3L brick

		return merged

	_chooseNeighborsToMergeWith3L: (mergeableNeighbors) =>
		numBricks = []
		maxBricks = 0

		for neighborSet, i in mergeableNeighbors
			continue if not neighborSet?
			numBricks.push {
				num: neighborSet.size
				index: i
			}
			maxBricks = Math.max maxBricks, neighborSet.size

		largestConnections = numBricks.filter (element) ->
			return element.num == maxBricks

		randomOfLargest = largestConnections[Random.next(largestConnections.length)]
		return randomOfLargest.index

	# main while loop condition:
	# any brick can still merge --> use heuristic:
	# keep a counter, break if last number of unsuccessful tries > (some number
	# or some % of total bricks in object)
	# !! Expects bricks to layout to be a Set !!
	layoutByGreedyMerge: (grid, bricksToLayout) =>
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

	###
	# Split up all supplied bricks into single bricks and relayout locally. This
	# means that all supplied bricks and their neighbors will be relayouted.
	#
	# @param {Set<Brick>} bricks bricks that should be split
	###
	splitBricksAndRelayoutLocally: (bricks, grid, useThreeLayers = true) =>
		bricksToSplit = new Set()

		bricks.forEach (brick) ->
			# add this brick to be split
			bricksToSplit.add brick

			# get neighbors in same z layer
			xp = brick.getNeighbors(Brick.direction.Xp)
			xm = brick.getNeighbors(Brick.direction.Xm)
			yp = brick.getNeighbors(Brick.direction.Yp)
			ym = brick.getNeighbors(Brick.direction.Ym)

			# add them all to be split as well
			xp.forEach (brick) -> bricksToSplit.add brick
			xm.forEach (brick) -> bricksToSplit.add brick
			yp.forEach (brick) -> bricksToSplit.add brick
			ym.forEach (brick) -> bricksToSplit.add brick

		newBricks = @_splitBricks bricksToSplit

		bricksToBeDeleted = new Set()

		newBricks.forEach (brick) ->
			brick.forEachVoxel (voxel) ->
				# delete bricks where voxels are disabled (3d printed)
				if not voxel.enabled
					# remove from relayout list
					bricksToBeDeleted.add brick
					# delete brick from structure
					brick.clear()

		bricksToBeDeleted.forEach (brick) ->
			newBricks.delete brick

		if useThreeLayers
			@layout3LBricks grid, newBricks
		@layoutByGreedyMerge grid, newBricks
		.then ->
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

	_findMergeableNeighborsUpOrDownwards: (brick, direction) =>
		# only handle plates (z=1)
		return null if brick.getSize().z != 1

		# check if 3layer Brick possible according to xy dimensions
		return null if !Brick.isValidSize brick.getSize().x, brick.getSize().y, 3

		# check if any slot is empty
		return null if brick.getStabilityInZDir(direction) != 1

		# then check if size of second layer fits
		# if size fits and no slot empty -> position fits
		secondLayerBricks = brick.getNeighbors(direction)
		sLIterator = secondLayerBricks.values()
		while sLBrick = sLIterator.next().value
			return null unless sLBrick.getSize().z == 1

		if @_sameSizeAsBrick brick, secondLayerBricks
			# check next layer
			thirdLayerBricks = new Set()
			sLIterator = secondLayerBricks.values()
			while sLBrick = sLIterator.next().value
				return unless sLBrick.getStabilityInZDir(direction) == 1
				neighbors = sLBrick.getNeighbors(direction)
				neighborsIter = neighbors.values()
				while nBrick = neighborsIter.next().value
					return unless nBrick.getSize().z == 1
					thirdLayerBricks.add nBrick

			if @_sameSizeAsBrick brick, thirdLayerBricks
				thirdLayerBricks.forEach (tlBrick) ->
					secondLayerBricks.add tlBrick
				return secondLayerBricks

		# no mergeable neighbors
		return null


	_sameSizeAsBrick: (brick, layerBricks) =>
		return false if layerBricks.size == 0

		sameSize = true
		p = brick.getPosition()
		s = brick.getSize()

		layerBricks.forEach (lBrick) ->
			if lBrick.getSize().z != 1
				sameSize = false
				return
			lp = lBrick.getPosition()
			ls = lBrick.getSize()

			xMinInBrick = lp.x >= p.x
			xMaxInBrick = lp.x + ls.x <= p.x + s.x
			yMinInBrick = lp.y >= p.y
			yMaxInBrick = lp.y + ls.y <= p.y + s.y

			if not (xMinInBrick and xMaxInBrick and yMinInBrick and yMaxInBrick)
				sameSize = false

		return sameSize


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

module.exports = BrickLayouter
