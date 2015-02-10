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

		###
		Brick.nextBrickIndex = 0

		brick0 = new Brick {x: 0, y: 0, z: 0}, {x: 1, y: 1, z: 1}
		brick1 = new Brick {x: 1, y: 0, z: 0}, {x: 1, y: 1, z: 1}
		brick2 = new Brick {x: 2, y: 0, z: 0}, {x: 1, y: 1, z: 1}
		brick3 = new Brick {x: 3, y: 0, z: 0}, {x: 1, y: 1, z: 1}

		brick4 = new Brick {x: 0, y: 0, z: 1}, {x: 1, y: 1, z: 1}
		brick5 = new Brick {x: 1, y: 0, z: 1}, {x: 2, y: 1, z: 1}
		brick6 = new Brick {x: 3, y: 0, z: 1}, {x: 1, y: 1, z: 1}

		brick7 = new Brick {x: 0, y: 0, z: 2}, {x: 4, y: 1, z: 1}

		brick8 = new Brick {x: 0, y: 0, z: 3}, {x: 1, y: 1, z: 1}
		brick9 = new Brick {x: 1, y: 0, z: 3}, {x: 1, y: 1, z: 1}
		brickA = new Brick {x: 2, y: 0, z: 3}, {x: 1, y: 1, z: 1}
		brickB = new Brick {x: 3, y: 0, z: 3}, {x: 1, y: 1, z: 1}

		brick0.neighbours = [[],[brick1],[],[]]
		brick0.upperSlots = [[brick4]]
		brick1.neighbours = [[brick0],[brick2],[],[]]
		brick1.upperSlots = [[brick5]]
		brick2.neighbours = [[brick1],[brick3],[],[]]
		brick2.upperSlots = [[brick5]]
		brick3.neighbours = [[brick2],[],[],[]]
		brick3.upperSlots = [[brick5]]

		brick4.neighbours = [[],[brick5],[],[]]
		brick4.upperSlots = [[brick7]]
		brick4.lowerSlots = [[brick0]]
		brick5.neighbours = [[brick4],[brick6],[],[]]
		brick5.upperSlots = [[brick7],[brick7]]
		brick5.lowerSlots = [[brick1],[brick2]]
		brick6.neighbours = [[brick5],[],[],[]]
		brick6.upperSlots = [[brick7]]
		brick6.lowerSlots = [[brick3]]

		brick7.neighbours = [[],[],[],[]]
		brick7.upperSlots = [[brick8],[brick9],[brickA],[brickB]]
		brick7.lowerSlots = [[brick4],[brick5],[brick5],[brick6]]

		brick8.neighbours = [[],[brick9],[],[]]
		brick8.lowerSlots = [[brick7]]
		brick9.neighbours = [[brick8],[brickA],[],[]]
		brick9.lowerSlots = [[brick7]]
		brickA.neighbours = [[brick9],[brickB],[],[]]
		brickA.lowerSlots = [[brick7]]
		brickB.neighbours = [[brickA],[],[],[]]
		brickB.lowerSlots = [[brick7]]

		layer0 = [brick0, brick1, brick2, brick3]
		layer1 = [brick4, brick5, brick6]
		layer2 = [brick7]
		layer3 = [brick8, brick9, brickA, brickB]
		bricks = [layer0, layer1, layer2, layer3]

		bricksToSplit = [brick5, brick7]

		newBricks = @_splitBricks bricksToSplit, bricks
		console.log newBricks
    ###

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

		return unless numTotalInitialBricks > 0

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
				break if otherBrick == brick
			biconnectedComponents.push component

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

	_splitBricks: (bricksToSplit, bricks) =>
		newBricks = []

		for brick in bricksToSplit
			newBricks.push brick.split()
			@_removeFirstOccurenceFromArray brick, bricks[brick.position.z]

		newBricks = [].concat.apply([], newBricks)

		for newBrick in newBricks
			bricks[newBrick.position.z].push newBrick

		return newBricks

