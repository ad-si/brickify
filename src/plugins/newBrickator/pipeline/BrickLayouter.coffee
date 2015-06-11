log = require 'loglevel'

Brick = require './Brick'
arrayHelper = require './arrayHelper'
Random = require './Random'

###
# @class BrickLayouter
###

class BrickLayouter
	constructor: (@pseudoRandom = false, @debugMode = false) ->
		Random.usePseudoRandom @pseudoRandom

	initializeBrickGraph: (grid) ->
		grid.initializeBricks()
		return grid

	layout3LBricks: (grid) ->
		numRandomChoices = 0
		numRandomChoicesWithoutMerge = 0
		numTotalInitialBricks = 0

		bricksToLayout = grid.getAllBricks()
		bricksToLayout.chooseRandomBrick = grid.chooseRandomBrick

		numTotalInitialBricks += bricksToLayout.size
		maxNumRandomChoicesWithoutMerge = numTotalInitialBricks / 2
		return unless numTotalInitialBricks > 0

		loop
			brick = @_chooseRandomBrick bricksToLayout
			return {grid: grid} unless brick?
			numRandomChoices++

			mergeableNeighbors = []# @_findMergeableNeighbors brick, useThreeLayers

			if !@_anyDefinedInArray(mergeableNeighbors)
				numRandomChoicesWithoutMerge++
				if numRandomChoicesWithoutMerge >= maxNumRandomChoicesWithoutMerge
					log.debug "\trandomChoices #{numRandomChoices}
											withoutMerge #{numRandomChoicesWithoutMerge}"
					break # done with initial layout
				else
					continue # randomly choose a new brick

			#@_mergeLoop brick, mergeableNeighbors, bricksToLayout

		return {grid: grid}

	# main while loop condition:
	# any brick can still merge --> use heuristic:
	# keep a counter, break if last number of unsuccessful tries > (some number
	# or some % of total bricks in object)
	# !! Expects bricks to layout to be a Set !!
	layoutByGreedyMerge: (grid, bricksToLayout, useThreeLayers = false) =>
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
			return {grid: grid} unless brick?
			numRandomChoices++
			
			mergeableNeighbors = @_findMergeableNeighbors brick, useThreeLayers

			if !@_anyDefinedInArray(mergeableNeighbors)
				numRandomChoicesWithoutMerge++
				if numRandomChoicesWithoutMerge >= maxNumRandomChoicesWithoutMerge
					log.debug "\trandomChoices #{numRandomChoices}
											withoutMerge #{numRandomChoicesWithoutMerge}"
					break # done with initial layout
				else
					continue # randomly choose a new brick

			@_mergeLoop brick, mergeableNeighbors, bricksToLayout

			###
			if brick.getStability() == 0
				neighborsXy = brick.getNeighborsXY()
				if neighborsXy.size != 0
					# split brick & neighbors into smallest components
					#console.log 'instability to be remedied'
					neighborsXy.add brick
					newBricks = @_splitBricks neighborsXy
					bricksToLayout.delete brick
					newBricks.forEach (newBrick) ->
						bricksToLayout.add newBrick
					console.log 'instability removed'
			###

		return {grid: grid}


	finalLayoutPass: (grid) =>
		bricksToLayout = grid.getAllBricks()
		finalPassMerges = 0
		bricksToLayout.forEach (brick) =>
			return unless brick?
			mergeableNeighbors = @_findMergeableNeighbors brick
			if @_anyDefinedInArray(mergeableNeighbors)
				finalPassMerges++
				@_mergeLoop brick, mergeableNeighbors, bricksToLayout

		log.debug '\tFinal pass merged ', finalPassMerges, ' times.'
		return {grid: grid}

	_mergeLoop: (brick, mergeableNeighbors, bricksToLayout) =>
		while(@_anyDefinedInArray(mergeableNeighbors))
			mergeIndex = @_chooseNeighborsToMergeWith mergeableNeighbors
			neighborsToMergeWith = mergeableNeighbors[mergeIndex]

			###
			console.log 'TO BE MERGED'
			if mergeIndex >= 4
				console.log 'into size', brick.getSize().x, brick.getSize().y, 3
			brick.debugLog()
			neighborsToMergeWith.forEach (fBrick) ->
				fBrick.debugLog()
			###

			@_mergeBricksAndUpdateGraphConnections brick,
				neighborsToMergeWith, bricksToLayout

			###
			console.log 'NEW BRICK', mergeIndex
			brick.debugLog()
			console.log brick.isValid()
			console.log '  '
			###

			if @debugMode and not brick.isValid()
				log.warn 'Invalid brick: ', brick
				log.warn '> Using pseudoRandom:', @pseudoRandom
				log.warn '> current seed:', Random.getSeed()

			mergeableNeighbors = @_findMergeableNeighbors brick

		return brick

	###
	# Split up all supplied bricks into single bricks and relayout locally. This
	# means that all supplied bricks and their neighbors will be relayouted.
	#
	# @param {Set<Brick>} bricks bricks that should be split
	###
	splitBricksAndRelayoutLocally: (bricks, grid, useThreeLayers = false) =>
		bricksToSplit = new Set()

		bricks.forEach (brick) ->
			# add this brick to be split
			bricksToSplit.add brick

			# get neighbours in same z layer
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

		@layoutByGreedyMerge grid, newBricks, useThreeLayers

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

	# chooses a random brick out of the set
	_chooseRandomBrick: (setOfBricks) ->
		###
		console.log 'choosing Random Brick'
		###
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

	# Searches for mergeable neighbours in [x-, x+, y-, y+] direction
	# and returns an array out of arrays of IDs for each direction
	_findMergeableNeighbors: (brick, useThreeLayers) =>
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
		if useThreeLayers
			mergeableNeighbors.push @_findMergeableNeighborsUpOrDownwards(
				brick
				Brick.direction.Zp
			)
			mergeableNeighbors.push @_findMergeableNeighborsUpOrDownwards(
				brick
				Brick.direction.Zm
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
		if neighborsInDirection.size == 0
			return null

		#special case: brick is 3 layer, all neighbors 1x1x1
		if brick.getSize().z == 3
			num1x1x1neighbors = 3 * widthFn(brick.getPosition())
			if neighborsInDirection.size == num1x1x1neighbors
				merge = true
				neighborsInDirection.forEach (neighbor) ->
					ns = neighbor.getSize()
					if not (ns.x == 1 and ns.y == 1 and ns.z == 1)
						merge = false
				if merge
					#check for valid brick size?
					console.warn 'special case'
					return neighborsInDirection

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

		if noMerge
			return null

		# if they have the same accumulative width
		# check if they are in the correct positions,
		# i.e. no spacing between neighbors
		if width == widthFn(brick.getSize())
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

			if invalidSize
				return null

			if Brick.isValidSize(widthFn(brick.getSize()), lengthFn(brick.getSize()) +
			length, brick.getSize().z)
				return neighborsInDirection
			else
				return null

	_findMergeableNeighborsUpOrDownwards: (brick, direction) =>
		noMerge = false

		if brick.getSize().z == 3
			return null

		# check if 3layer Brick possible according to xy dimensions
		if !Brick.isValidSize brick.getSize().x, brick.getSize().y, 3
			return null

		# check if any slot is empty
		if brick.getStabilityInDir(direction) != 1
			return null

		# then check if size of second layer fits
		# if size fits and no slot empty -> position fits
		secondLayerBricks = brick.getNeighbors(direction)
		secondLayerBricks.forEach (slBrick) ->
			if slBrick.getSize().z != 1
				noMerge = true
		if noMerge
			return null

		if @_layerHasSameSizeAsBrick brick, secondLayerBricks
			# check next layer
			thirdLayerBricks = new Set()
			secondLayerBricks.forEach (sLBrick) ->
				if sLBrick.getStabilityInDir(direction) != 1
					noMerge = true
				sLBrick.getNeighbors(direction).forEach (nBrick) ->
					if nBrick.getSize().z != 1
						noMerge = true
					thirdLayerBricks.add nBrick

			if noMerge
				return null

			if @_layerHasSameSizeAsBrick brick, thirdLayerBricks
				thirdLayerBricks.forEach (tlBrick) ->
					secondLayerBricks.add tlBrick
				return secondLayerBricks

		# no mergeable neighbors
		return null


	_layerHasSameSizeAsBrick: (brick, layerBricks) =>
		sameSize = true
		p = brick.getPosition()
		s = brick.getSize()

		if layerBricks.size == 0
			return false

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

			###
			if i == 4 or i == 5
				connectedBricks = new Set()
				connectedBricks.add 1
			###

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
