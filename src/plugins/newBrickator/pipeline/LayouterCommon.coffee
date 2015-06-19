Random = require './Random'

# chooses a random brick out of the set
module.exports.chooseRandomBrick = (setOfBricks) ->
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

module.exports.mergeBricksAndUpdateGraphConnections = (
		brick, mergeNeighbors, bricksToLayout ) ->

	mergeNeighbors.forEach (neighborToMergeWith) ->
		bricksToLayout.delete neighborToMergeWith
		brick.mergeWith neighborToMergeWith

	return brick
