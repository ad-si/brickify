log = require 'loglevel'

Random = require '../Random'
DataHelper = require '../DataHelper'

###
# @class PlateLayouter
#
# Abstract class containing most of the execution logic
# for inheriting classes
###

class Layouter
	constructor: ->
		return

	###
	# Performs one layout pass.
	#
	# @param {Grid} grid the grid that contains the voxels/bricks to be layouted
	# @param {Set<Brick>} [bricksToLayout] if present, layouter only works on
	# the bricks in this set, not on the entire grid
	# @return {Grid} updated version of the original grid passed to the function
	###
	layout: (grid, bricksToLayout) ->
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

			if @_isPlateLayouter() and brick.getSize().z is 3
				bricksToLayout.delete brick
				return Promise.resolve {grid: grid} if bricksToLayout.size is 0
				continue

			merged = @_mergeLoop brick, bricksToLayout

			if not merged
				numRandomChoicesWithoutMerge++
				if numRandomChoicesWithoutMerge >= maxNumRandomChoicesWithoutMerge
					log.debug "\trandomChoices #{numRandomChoices}
												withoutMerge #{numRandomChoicesWithoutMerge}"
					# Done with layout
					break
				else
					# Choose a new brick
					continue

			if @_isBrickLayouter()
				# If brick is 1x1x3, 1x2x3 or instable after mergeLoop
				# break it into pieces ...
				if brick.isSize(1, 1, 3) or brick.getStability() is 0 or
				brick.isSize(1, 2, 3)
					# .. unless it has no neighbors ..
					neighbors = brick.getNeighborsXY()
					continue if neighbors.size == 0
					neighborIterator = neighbors.values()
					#.. unless all neighbors are already bricks
					while neighbor = neighborIterator.next().value
						continue if neighbor.getSize().z == 1
					newBricks = brick.splitUp()
					bricksToLayout.delete brick
					newBricks.forEach (newBrick) ->
						bricksToLayout.add newBrick

		return Promise.resolve {grid: grid}

	# Chooses a random brick out of the set
	_chooseRandomBrick: (setOfBricks) =>
		if setOfBricks.size is 0
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

	_mergeBricksAndUpdateGraphConnections: (brick,
			mergeNeighbors, bricksToLayout) =>
		mergeNeighbors.forEach (neighborToMergeWith) ->
			bricksToLayout.delete neighborToMergeWith
			brick.mergeWith neighborToMergeWith
		return brick


	_mergeLoop: (brick, bricksToLayout) =>
		merged = false

		mergeableNeighbors = @_findMergeableNeighbors brick

		while(DataHelper.anyDefinedInArray(mergeableNeighbors))
			merged = true
			mergeIndex = @_chooseNeighborsToMergeWith mergeableNeighbors
			neighborsToMergeWith = mergeableNeighbors[mergeIndex]

			@_mergeBricksAndUpdateGraphConnections brick,
				neighborsToMergeWith, bricksToLayout

			if not brick.isValid()
				log.warn 'Invalid brick: ', brick
				log.warn '> Using pseudoRandom:', Random.usePseudoRandom
				log.warn '> current seed:', Random.getSeed()

			mergeableNeighbors = @_findMergeableNeighbors brick

		return merged

module.exports = Layouter
