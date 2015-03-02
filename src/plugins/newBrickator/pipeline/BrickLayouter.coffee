Brick = require './Brick'
BrickGraph = require './BrickGraph'
arrayHelper = require './arrayHelper'

module.exports = class BrickLayouter
	constructor: (pseudoRandom = false) ->
		if pseudoRandom
			@seed = 42
			@_random = @_pseudoRandom
		return

	initializeBrickGraph: (grid) =>
		brickGraph = new BrickGraph(grid)
		return {brickGraph: brickGraph}

	# main while loop condition:
	# any brick can still merge --> use heuristic:
	# keep a counter, break if last number of unsuccessful tries > (some number
	# or some % of total bricks in object)
	layoutByGreedyMerge: (brickGraph, bricksToLayout) =>
		numRandomChoices = 0
		numRandomChoicesWithoutMerge = 0
		numTotalInitialBricks = 0

		if not bricksToLayout?
			bricksToLayout = brickGraph.bricks

		for layer in bricksToLayout
			numTotalInitialBricks += layer.length
		maxNumRandomChoicesWithoutMerge = numTotalInitialBricks

		return unless numTotalInitialBricks > 0

		loop
			brick = @_chooseRandomBrick bricksToLayout
			if !brick?
				return {brickGraph: brickGraph}

			numRandomChoices++
			mergeableNeighbours = @_findMergeableNeighbours brick

			if !@_anyDefined(mergeableNeighbours)
				numRandomChoicesWithoutMerge++
				if numRandomChoicesWithoutMerge >= maxNumRandomChoicesWithoutMerge
					console.log " - randomChoices #{numRandomChoices}
											withoutMerge #{numRandomChoicesWithoutMerge}"
					# done with initial layout
					break
				else
					# randomly choose a new brick
					continue

			while(@_anyDefined(mergeableNeighbours))
				mergeIndex = @_chooseNeighboursToMergeWith mergeableNeighbours
				brick = @_mergeBricksAndUpdateGraphConnections brick,
					mergeableNeighbours, mergeIndex, brickGraph, bricksToLayout
				mergeableNeighbours = @_findMergeableNeighbours brick

		return {brickGraph: brickGraph}

	optimizeForStability: (bricks) =>
		for layer in bricks # access removed element?
			for brick in layer
				if brick? and brick.uniqueConnectedBricks().length is 0
					console.log brick
					if brick.uniqueNeighbours().length is 0
						0
						#arrayHelper.removeFirstOccurenceFromArray brick, bricks[brick.position.z]
					else
						console.log 'splitting brick and relayouting'
						console.log brick
						neighbours = brick.uniqueNeighbours()
						oldBricks = neighbours.concat(brick)
						@_splitBricksAndRelayout oldBricks, bricks

		#console.log @_findWeakArticulationPoints bricks

	_splitBricksAndRelayout: (oldBricks, bricks) =>
		newBricks = @_splitBricks oldBricks, bricks
		@layoutByGreedyMerge bricks
		return

	splitBricksAndRelayoutLocally: (oldBricks, brickGraph, grid) =>
		# split up all bricks into single bricks
		bricksToSplit = []

		for brick in oldBricks
			bricksToSplit = bricksToSplit.concat brick.uniqueNeighbours()
			bricksToSplit.push brick

		bricksToSplit = arrayHelper.removeDuplicates bricksToSplit

		newBricks = @_splitBricks bricksToSplit, brickGraph

		legoBricks = []
		for brick in newBricks
			p = brick.position
			if grid? and not grid.zLayers[p.z][p.x][p.y].enabled
				# This voxel is going to be 3d printed --> delete brick
				brickGraph.deleteBrick brick
			else
				legoBricks.push brick

		# reset visible material
		for brick in legoBricks
			brick.visualizationMaterial = null

		@layoutByGreedyMerge brickGraph, [legoBricks]

		return {
			removedBricks: bricksToSplit
			newBricks: legoBricks
		}

	_splitBricks: (bricksToSplit, brickGraph) =>
		newBricks = []

		for brick in bricksToSplit
			newBricks = newBricks.concat brick.split()
			brickGraph.deleteBrick brick

		for newBrick in newBricks
			brickGraph.bricks[newBrick.position.z].push newBrick

		return newBricks

	_anyDefined: (mergeableNeighbours) =>
		return mergeableNeighbours.some (entry) -> entry?

	_chooseRandomBrick: (brickLayers) =>
		i = 0
		brickList = brickLayers[@_random(brickLayers.length)]

		while brickList.length is 0 # if a layer has no bricks, retry
			if ++i >= brickLayers.length
				return null
			brickList = brickLayers[@_random(brickLayers.length)]

		brick = brickList[@_random(brickList.length)]
		return brick

	_random: (max) =>
		Math.floor(Math.random() * max)

	_pseudoRandom: (max) =>
		@seed = (1103515245 * @seed + 12345) % 2 ^ 31
		@seed % max

	_findMergeableNeighbours: (brick) =>
		mergeableNeighbours = []

		mergeableNeighbours.push @_findMergeableNeighboursInDirection(
			brick
			Brick.direction.Xm
			(obj) -> return obj.y
			(obj) -> return obj.x
		)
		mergeableNeighbours.push @_findMergeableNeighboursInDirection(
			brick
			Brick.direction.Xp
			(obj) -> return obj.y
			(obj) -> return obj.x
		)
		mergeableNeighbours.push @_findMergeableNeighboursInDirection(
			brick
			Brick.direction.Ym
			(obj) -> return obj.x
			(obj) -> return obj.y
		)
		mergeableNeighbours.push @_findMergeableNeighboursInDirection(
			brick
			Brick.direction.Yp
			(obj) -> return obj.x
			(obj) -> return obj.y
		)

		return mergeableNeighbours

	_findMergeableNeighboursInDirection: (brick, dir, widthFn, lengthFn) =>
		if brick.neighbours[dir].length > 0
			width = 0
			for neighbour in brick.neighbours[dir]
				width += widthFn neighbour.size
			if width == widthFn(brick.size)
				minWidth = widthFn brick.position
				maxWidth = widthFn(brick.position) + widthFn(brick.size) - 1
				length = lengthFn(brick.neighbours[dir][0].size)
				for neighbour in brick.neighbours[dir]
					if widthFn(neighbour.position) < minWidth
						return
					else if widthFn(neighbour.position) +
					widthFn(neighbour.size) - 1 > maxWidth
						return
					if lengthFn(neighbour.size) != length
						return
				if Brick.isValidSize(widthFn(brick.size), lengthFn(brick.size) +
				length, brick.size.z)
					return brick.neighbours[dir]

	# Returns the index of the mergeableNeighbours sub-array,
	# where the bricks have the most connected neighbours.
	# If multiple sub-arrays have the same number of connected neigbours,
	# one is randomly chosen
	_chooseNeighboursToMergeWith: (mergeableNeighbours) =>
		numConnections = []
		maxConnections = 0

		for neighbours, i in mergeableNeighbours
			connectedBricks = []
			continue if not neighbours
			
			for neighbour in neighbours
				connectedBricks = connectedBricks.concat neighbour.uniqueConnectedBricks()
			connectedBricks = arrayHelper.removeDuplicates connectedBricks

			numConnections.push {
				num: connectedBricks.length
				index: i
			}
			maxConnections = Math.max maxConnections, connectedBricks.length

		largestConnections = numConnections.filter (element) ->
			return element.num == maxConnections

		randomOfLargest = largestConnections[@_random(largestConnections.length)]
		return randomOfLargest.index

	_mergeBricksAndUpdateGraphConnections: (
		brick, mergeableNeighbours, mergeIndex, brickGraph, bricksToLayout ) =>

		mergeNeighbours = mergeableNeighbours[mergeIndex]

		ps = brick.getPositionAndSizeForNewBrick mergeIndex, mergeNeighbours
		newBrick = new Brick(ps.position, ps.size)

		#save oldBricks in newBrick for debugging
		newBrick.mergedNeighbours = mergeNeighbours
		newBrick.mergedBrick = brick

		# set new brick connections & neighbours
		for neighbour in mergeNeighbours
			newBrick.getConnectionsFromMergingBrick neighbour
			newBrick.getNeighboursFromMergingBrick neighbour
		newBrick.getConnectionsFromMergingBrick brick
		newBrick.getNeighboursFromMergingBrick brick

		# delete outdated bricks from bricks array
		z = brick.position.z
		arrayHelper.removeFirstOccurenceFromArray brick, brickGraph.bricks[z]
		if bricksToLayout
			arrayHelper.removeFirstOccurenceFromArray brick, bricksToLayout[0]
		for neighbour in mergeNeighbours
			arrayHelper.removeFirstOccurenceFromArray neighbour, brickGraph.bricks[z]
			if bricksToLayout
				arrayHelper.removeFirstOccurenceFromArray neighbour, bricksToLayout[0]

		# add newBrick to bricks array
		brickGraph.bricks[z].push newBrick
		return newBrick

	_getBiconnectedComponents: (bricks) =>
		@index = 0
		biconnectedComponents = []
		stack = []
		for zLayer in bricks
			for brick in zLayer
				if brick.biconnectedComponentId == undefined
					@_tarjanAlgorithm brick, biconnectedComponents, stack
		biconnectedComponents

	_tarjanAlgorithm: (brick, biconnectedComponents, stack) =>
		brick.biconnectedComponentId = @index
		brick.lowlink = @index
		@index++
		stack.push(brick)
		for connectedBrick in brick.uniqueConnectedBricks()
			if connectedBrick.biconnectedComponentId == undefined
				@_tarjanAlgorithm(connectedBrick, biconnectedComponents, stack)
				brick.lowlink = if brick.lowlink < connectedBrick.lowlink
				then brick.lowlink else connectedBrick.lowlink
			else if stack.indexOf(connectedBrick) > -1
				brick.lowlink = if brick.lowlink < connectedBrick.lowlink
				then brick.lowlink else connectedBrick.lowlink

		if brick.lowlink == brick.biconnectedComponentId
			otherBrick = null
			component = []
			while true
				otherBrick = stack.pop()
				component.push otherBrick
				break if otherBrick == brick
			biconnectedComponents.push component

	_findWeakArticulationPoints: (bricks) =>
		# filter out trivial articulation points
		return @_getArticulationPoints bricks

	_getArticulationPoints: (bricks) =>
		@time = 0
		articulationPoints = []
		for zLayer in bricks
			for brick in zLayer
				brick.discovered = false
				brick.parent = null
				brick.discoveryTime = -1
		for zLayer in bricks
			for brick in zLayer
				if brick.discovered == undefined or !brick.discovered
					@_articulationPointAlgorithm brick, articulationPoints
		articulationPoints

	_articulationPointAlgorithm: (brick, articulationPoints) =>
		brick.discoveryTime = brick.lowlink = ++@time
		brick.discovered = true
		children = 0
		for otherBrick in brick.uniqueConnectedBricks()
			if otherBrick.discovered is undefined or !otherBrick.discovered
				otherBrick.parent = brick
				children++
				@_articulationPointAlgorithm otherBrick, articulationPoints
				brick.lowlink = Math.min brick.lowlink, otherBrick.lowlink
				if !brick.parent? and children > 1
					articulationPoints.push brick
				if brick.parent?
					if otherBrick.lowlink >= brick.discoveryTime
						articulationPoints.push brick
			else if otherBrick.parent != brick
				brick.lowlink = Math.min brick.lowlink, otherBrick.discoveryTime
