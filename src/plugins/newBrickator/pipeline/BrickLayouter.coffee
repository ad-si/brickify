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

	_mergeBricksAndUpdateGraphConnections: (
		brick, mergeNeighbors, bricksToLayout ) ->

		mergeNeighbors.forEach (neighborToMergeWith) ->
			bricksToLayout.delete neighborToMergeWith
			brick.mergeWith neighborToMergeWith

		return brick

module.exports = BrickLayouter
