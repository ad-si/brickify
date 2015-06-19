Random = require './Random'
DataHelper = require './DataHelper'

class LayouterCommon

# chooses a random brick out of the set
	@chooseRandomBrick: (setOfBricks) =>
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

	@mergeBricksAndUpdateGraphConnections: (brick,
			mergeNeighbors, bricksToLayout) =>
		mergeNeighbors.forEach (neighborToMergeWith) ->
			bricksToLayout.delete neighborToMergeWith
			brick.mergeWith neighborToMergeWith
		return brick


	@mergeLoop: (layouter, brick, bricksToLayout) =>
		merged = false

		mergeableNeighbors = layouter._findMergeableNeighbors brick

		while(DataHelper.anyDefinedInArray(mergeableNeighbors))
			merged = true
			mergeIndex = layouter._chooseNeighborsToMergeWith mergeableNeighbors
			neighborsToMergeWith = mergeableNeighbors[mergeIndex]

			@mergeBricksAndUpdateGraphConnections brick,
				neighborsToMergeWith, bricksToLayout

			if @debugMode and not brick.isValid()
				log.warn 'Invalid brick: ', brick
				log.warn '> Using pseudoRandom:', @pseudoRandom
				log.warn '> current seed:', Random.getSeed()

			mergeableNeighbors = layouter._findMergeableNeighbors brick

		return merged

module.exports = LayouterCommon
