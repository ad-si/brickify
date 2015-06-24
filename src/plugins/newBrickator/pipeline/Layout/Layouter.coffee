log = require 'loglevel'

Random = require '../Random'
DataHelper = require '../DataHelper'

class Layouter
	constructor: ->
		return

	layout: (grid, bricksToLayout) ->
		numRandomChoices = 0
		numRandomChoicesWithoutMerge = 0
		numTotalInitialBricks = 0

		if not bricksToLayout?
			bricksToLayout = grid.getAllBricks()
			bricksToLayout.chooseRandomBrick = grid.chooseRandomBrick

		numTotalInitialBricks += bricksToLayout.size
		maxNumRandomChoicesWithoutMerge = numTotalInitialBricks
		return {grid: grid} unless numTotalInitialBricks > 0

		loop
			brick = @chooseRandomBrick bricksToLayout
			if !brick?
				return Promise.resolve {grid: grid}
			numRandomChoices++

			if @isPlateLayouter() and brick.getSize().z is 3
				bricksToLayout.delete brick
				return Promise.resolve {grid: grid} if bricksToLayout.size is 0
				continue

			merged = @mergeLoop brick, bricksToLayout

			if not merged
				numRandomChoicesWithoutMerge++
				if numRandomChoicesWithoutMerge >= maxNumRandomChoicesWithoutMerge
					log.debug "\trandomChoices #{numRandomChoices}
												withoutMerge #{numRandomChoicesWithoutMerge}"
					break # done with layout
				else
					continue # randomly choose a new brick

			if @isBrickLayouter()
				# if brick is 1x1x3, 1x2x3 or instable after mergeLoop
				# break it into pieces
				if brick.isSize(1, 1, 3) or brick.getStability() is 0 or
				brick.isSize(1, 2, 3)
					# TODO, dont split up if all neighbors are 3L already
					newBricks = brick.splitUp()
					bricksToLayout.delete brick
					newBricks.forEach (newBrick) ->
						bricksToLayout.add newBrick

		return Promise.resolve {grid: grid}

	# chooses a random brick out of the set
	chooseRandomBrick: (setOfBricks) =>
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

	mergeBricksAndUpdateGraphConnections: (brick,
			mergeNeighbors, bricksToLayout) =>
		mergeNeighbors.forEach (neighborToMergeWith) ->
			bricksToLayout.delete neighborToMergeWith
			brick.mergeWith neighborToMergeWith
		return brick


	mergeLoop: (brick, bricksToLayout) =>
		merged = false

		mergeableNeighbors = @_findMergeableNeighbors brick

		while(DataHelper.anyDefinedInArray(mergeableNeighbors))
			merged = true
			mergeIndex = @_chooseNeighborsToMergeWith mergeableNeighbors
			neighborsToMergeWith = mergeableNeighbors[mergeIndex]

			@mergeBricksAndUpdateGraphConnections brick,
				neighborsToMergeWith, bricksToLayout

			if not brick.isValid()
				log.warn 'Invalid brick: ', brick
				log.warn '> Using pseudoRandom:', @pseudoRandom
				log.warn '> current seed:', Random.getSeed()

			mergeableNeighbors = @_findMergeableNeighbors brick

		return merged

module.exports = Layouter
