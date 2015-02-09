Brick = require './Brick'

module.exports = class BrickLayouter
	constructor: () ->
		return

	initializeBrickGraph: (grid) =>
		bricks = []
		Brick.nextBrickIndex = 0
		for z in [0..grid.numVoxelsZ - 1] by 1
			bricks[z] = []

		# create all bricks
		for z in [0..grid.numVoxelsZ - 1] by 1
			for x in [0..grid.numVoxelsX - 1] by 1
				for y in [0..grid.numVoxelsY - 1] by 1

					if grid.zLayers[z]?[x]?[y]?
						if @_testVoxelExistsAndEnabled grid, z, x, y

							# create brick
							position = {x: x, y: y, z: z}
							size = {x: 1,y: 1,z: 1}
							brick = new Brick position, size
							#brick.id = @nextBrickIdx()
							grid.zLayers[z][x][y].brick = brick

							@_connectToBrickBelow brick, x,y,z, grid
							@_connectToBrickXm brick, x,y,z, grid
							@_connectToBrickYm brick, x,y,z, grid

							bricks[z].push brick

		# console.log bricks
		return {bricks: bricks}

	_connectToBrickBelow: (brick, x, y, z, grid) =>
		if z > 0 and grid.zLayers[z - 1]?[x]?[y]? and
		@_testVoxelExistsAndEnabled grid, z - 1, x, y
			brickBelow = grid.zLayers[z - 1][x][y].brick
			brick.lowerSlots[0][0] = brickBelow
			brickBelow.upperSlots[0][0] = brick
		return

	_connectToBrickXm: (brick, x, y, z, grid) =>
		if x > 0 and grid.zLayers[z]?[x - 1]?[y]? and
		@_testVoxelExistsAndEnabled grid, z, x - 1, y
			brick.neighbours[0] = [grid.zLayers[z][x - 1][y].brick]
			grid.zLayers[z][x - 1][y].brick.neighbours[1] = [brick]
		return

	_connectToBrickYm: (brick, x, y, z, grid) =>
		if y > 0 and grid.zLayers[z]?[x]?[y - 1]? and
		@_testVoxelExistsAndEnabled grid, z, x, y - 1
			brick.neighbours[2] = [grid.zLayers[z][x][y - 1].brick]
			grid.zLayers[z][x][y - 1].brick.neighbours[3] = [brick]
		return

	_testVoxelExistsAndEnabled: (grid, z, x, y) =>
		if (grid.zLayers[z][x][y] == false)
			return false
		return grid.zLayers[z][x][y].enabled == true

	# main while loop condition:
	# any brick can still merge --> use heuristic:
	# keep a counter, break if last number of unsuccessful tries > (some number
	# or some % of total bricks in object)
	layoutByGreedyMerge: (bricks) =>
		numRandomChoices = 0
		numRandomChoicesWithoutMerge = 0
		numTotalInitialBricks = 0
		for layer in bricks
			numTotalInitialBricks += layer.length
		maxNumRandomChoicesWithoutMerge = numTotalInitialBricks

		while(true) #only for debugging, should be while true
			brick = @_chooseRandomBrick bricks
			numRandomChoices++
			#console.log numRandomChoices
			mergeableNeighbours = @_findMergeableNeighbours brick

			if !@_anyDefined(mergeableNeighbours)
				numRandomChoicesWithoutMerge++
				if numRandomChoicesWithoutMerge >= maxNumRandomChoicesWithoutMerge
					console.log " - randomChoices #{numRandomChoices}
											withoutMerge #{numRandomChoicesWithoutMerge}"
					break # done with initial layout
				else
					continue # randomly choose a new brick

			while(@_anyDefined(mergeableNeighbours))
				mergeIndex = @_chooseNeighboursToMergeWith mergeableNeighbours
				brick = @_mergeBricksAndUpdateGraphConnections brick,
					mergeableNeighbours, mergeIndex, bricks
				mergeableNeighbours = @_findMergeableNeighbours brick

		return {bricks: bricks}

	_anyDefined: (mergeableNeighbours) =>
		boolean = false
		for neighbours in mergeableNeighbours
			boolean = boolean or neighbours?
		return boolean

	_chooseRandomBrick: (bricks) =>
		brickLayer = bricks[Math.floor(Math.random() * bricks.length)]
		while brickLayer.length is 0 # if a layer has no bricks, retry
			brickLayer = bricks[Math.floor(Math.random() * bricks.length)]
		brick = brickLayer[Math.floor(Math.random() * brickLayer.length)]
		return brick

	_findMergeableNeighbours: (brick) =>
		mergeableNeighbours = []

		mergeableNeighbours.push @_findMergeableNeighboursInDirection(
			brick
			0
			(obj) -> return obj.y
			(obj) -> return obj.x
		)
		mergeableNeighbours.push @_findMergeableNeighboursInDirection(
			brick
			1
			(obj) -> return obj.y
			(obj) -> return obj.x
		)
		mergeableNeighbours.push @_findMergeableNeighboursInDirection(
			brick
			2
			(obj) -> return obj.x
			(obj) -> return obj.y
		)
		mergeableNeighbours.push @_findMergeableNeighboursInDirection(
			brick
			3
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


	_chooseNeighboursToMergeWith: (mergeableNeighbours) =>
		numConnections = []
		for neighbours, i in mergeableNeighbours
			connectedBricks = []
			if neighbours
				for neighbour in neighbours
					connectedBricks = connectedBricks.concat neighbour.uniqueConnectedBricks()
				connectedBricks = removeDuplicates connectedBricks
				numConnections[i] = connectedBricks.length

		maxConnections = 0
		largestIndices = []
		for num, i in numConnections
			if num > maxConnections
				maxConnections = num
		for num, i in numConnections
			if num == maxConnections
				largestIndices.push i

		randomOfLargestIndices = largestIndices[Math.floor(Math.random() *
			largestIndices.length)]
		return randomOfLargestIndices

	_mergeBricksAndUpdateGraphConnections: (
		brick, mergeableNeighbours, mergeIndex, bricks ) =>
		mergeNeighbours = mergeableNeighbours[mergeIndex]

		ps = brick.getPositionAndSizeForNewBrick mergeIndex, mergeNeighbours
		newBrick = new Brick(ps.position, ps.size)
		#newBrick.id = @nextBrickIdx()

		# set new brick connections & neighbours
		for mbrick in mergeNeighbours.concat [brick]
			newBrick.getConnectionsFromMergingBrick mbrick
			newBrick.getNeighboursFromMergingBrick mbrick

		# delete outdated bricks from bricks array
		z = brick.position.z
		@_removeFirstOccurenceFromArray brick, bricks[z]
		for neighbour in mergeNeighbours
			@_removeFirstOccurenceFromArray neighbour, bricks[z]

		# add newBrick to bricks array
		bricks[z].push newBrick
		return newBrick

	_findWeakArticulationPointsInGraph: (bricks) =>
		return

	###
	_neighbourMergeIndices: (mergeIndex) =>
		if mergeIndex == 0
			opposite = 1
			sides = [2, 3]
		else if mergeIndex == 1
			opposite = 0
			sides = [2, 3]
		else if mergeIndex == 2
			opposite = 3
			sides = [0, 1]
		else if mergeIndex == 3
			opposite = 2
			sides = [0, 1]
		return {opposite: opposite, sides: sides}
		###

	_removeFirstOccurenceFromArray: (object, array) =>
		i = array.indexOf object
		if i != -1
			array.splice i, 1
		return

	# helper method, to be moved somewhere more appropriate
	removeDuplicates = (array) ->
		a = array.concat()
		i = 0

		while i < a.length
			j = i + 1
			while j < a.length
				a.splice j--, 1  if a[i] is a[j]
				++j
			++i
		return a

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
				break unless otherBrick != brick
			biconnectedComponents.push component

	_splitBricks: (bricksToSplit, bricks) =>
		newBricks = []

		for brick in bricksToSplit
			newBricks.push brick.split()
			#remove brick from bricks

		newBricks = [].concat.apply([], newBricks)

		for newBrick in newBricks
			bricks[newBrick.position.z].push newBrick

		return newBricks

