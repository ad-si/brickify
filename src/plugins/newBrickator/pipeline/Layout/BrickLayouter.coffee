log = require 'loglevel'

Brick = require '../Brick'
Voxel = require '../Voxel'
DataHelper = require '../DataHelper'
Random = require '../Random'
Layouter = require './Layouter'

###
# @class BrickLayouter
###

class BrickLayouter extends Layouter
	constructor: (pseudoRandom = false) ->
		Random.usePseudoRandom pseudoRandom

	_isBrickLayouter: ->
		return true

	_isPlateLayouter: ->
		return false

	_findMergeableNeighbors: (brick) =>
		mergeableNeighbors = []

		if brick.getSize().z is 1
			mergeableNeighbors.push @_findMergeableNeighborsUpOrDownwards(
				brick
				Brick.direction.Zp
			)
			mergeableNeighbors.push @_findMergeableNeighborsUpOrDownwards(
				brick
				Brick.direction.Zm
			)
			return mergeableNeighbors

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

	_findMergeableNeighborsInDirection: (brick, dir, widthFn, lengthFn) =>
		voxels = brick.voxels
		mergeVoxels = new Set()
		mergeBricks = new Set()

		if widthFn(brick.getSize()) > 2 and lengthFn(brick.getSize()) >= 2
			return null

		# Find neighbor voxels, noMerge if any is empty
		voxelIter = voxels.values()
		while voxel = voxelIter.next().value
			mVoxel = voxel.neighbors[dir]
			return null unless mVoxel?
			mergeVoxels.add mVoxel unless mVoxel.brick is brick

		# Find neighbor bricks,
		# noMerge if any not present
		# noMerge if any brick not 1x1x1
		mergeVoxelIter = mergeVoxels.values()
		while mVoxel = mergeVoxelIter.next().value
			mBrick = mVoxel.brick
			return null unless mBrick and mBrick.isSize(1, 1, 1)
			mergeBricks.add mBrick

		allVoxels = DataHelper.union [voxels, mergeVoxels]

		size = Voxel.sizeFromVoxels(allVoxels)
		if Brick.isValidSize(size.x, size.y, size.z)
			return mergeBricks if @_minFractionOfConnectionsPresent(allVoxels)

		# Check another set of voxels in merge direction, starting from mergeVoxels
		# This is necessary for the 2 brick steps of larger bricks
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
			return mergeBricks if @_minFractionOfConnectionsPresent(allVoxels)

		return null

	###
		Check if at least half of the top and half of the bottom voxels
		offer connection possibilities
		This is used as a heuristic to determine whether or not to merge bricks:
		if a brick has less than minFraction connection
		it may lead to a more unstable layout
	###
	_minFractionOfConnectionsPresent: (voxels) =>
		minFraction = .51
		fraction = Voxel.fractionOfConnections voxels
		return fraction >= minFraction

	_chooseNeighborsToMergeWith: (mergeableNeighbors) =>
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
			return element.num is maxBricks

		randomOfLargest = largestConnections[Random.next(largestConnections.length)]
		return randomOfLargest.index

	_findMergeableNeighborsUpOrDownwards: (brick, direction) =>
		# Only handle plates (z=1)
		return null if brick.getSize().z != 1

		# Check if 3layer Brick possible according to xy dimensions
		return null if !Brick.isValidSize brick.getSize().x, brick.getSize().y, 3

		# Check if any slot is empty
		return null if brick.fractionOfConnectionsInZDirection(direction) != 1

		# Then check if size of second layer fits
		# if size fits and no slot empty -> position fits
		secondLayerBricks = brick.getNeighbors(direction)
		sLIterator = secondLayerBricks.values()
		while sLBrick = sLIterator.next().value
			return null unless sLBrick.getSize().z is 1

		if @_sameSizeAsBrick brick, secondLayerBricks
			# Check next layer
			thirdLayerBricks = new Set()
			sLIterator = secondLayerBricks.values()
			while sLBrick = sLIterator.next().value
				return unless sLBrick.fractionOfConnectionsInZDirection(direction) is 1
				neighbors = sLBrick.getNeighbors(direction)
				neighborsIter = neighbors.values()
				while nBrick = neighborsIter.next().value
					return unless nBrick.getSize().z is 1
					thirdLayerBricks.add nBrick

			if @_sameSizeAsBrick brick, thirdLayerBricks
				thirdLayerBricks.forEach (tlBrick) ->
					secondLayerBricks.add tlBrick
				return secondLayerBricks

		# No mergeable neighbors
		return null


	_sameSizeAsBrick: (brick, layerBricks) =>
		return false if layerBricks.size is 0

		p = brick.getPosition()
		s = brick.getSize()

		lBIterator = layerBricks.values()
		while lBrick = lBIterator.next().value
			if lBrick.getSize().z != 1
				return false
			lp = lBrick.getPosition()
			ls = lBrick.getSize()

			xMinInBrick = lp.x >= p.x
			xMaxInBrick = lp.x + ls.x <= p.x + s.x
			yMinInBrick = lp.y >= p.y
			yMaxInBrick = lp.y + ls.y <= p.y + s.y

			if not (xMinInBrick and xMaxInBrick and yMinInBrick and yMaxInBrick)
				return false

		return true

module.exports = BrickLayouter
