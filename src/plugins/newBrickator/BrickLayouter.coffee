Brick = require './Brick'

module.exports = class BrickLayouter
	constructor: () ->
		@nextBrickIndex = 0
		return

	nextBrickIdx: () =>
		temp = @nextBrickIndex
		@nextBrickIndex++
		#console.log temp
		return temp

	initializeBrickGraph: (grid) =>
		bricks = []
		@nextBrickIndex = 0
		for z in [0..grid.numVoxelsZ - 1] by 1
			bricks[z] = []

		# create all bricks
		for z in [0..grid.numVoxelsZ - 1] by 1
			for x in [0..grid.numVoxelsX - 1] by 1
				for y in [0..grid.numVoxelsY - 1] by 1

					if grid.zLayers[z]?[x]?[y]?
						if grid.zLayers[z][x][y] != false

							# create brick
							position = {x: x, y: y, z: z}
							size = {x: 1,y: 1,z: 1}
							brick = new Brick position, size
							brick.id = @nextBrickIdx()
							grid.zLayers[z][x][y].brick = brick

							@_connectToBrickBelow brick, x,y,z, grid
							@_connectToBrickXm brick, x,y,z, grid
							@_connectToBrickYm brick, x,y,z, grid

							bricks[z].push brick

		# console.log bricks
		return {bricks: bricks}

	_connectToBrickBelow: (brick, x, y, z, grid) =>
		if z > 0 and grid.zLayers[z - 1]?[x]?[y]? and
		grid.zLayers[z - 1][x][y] != false
			brickBelow = grid.zLayers[z - 1][x][y].brick
			brick.lowerSlots[0][0] = brickBelow
			brickBelow.upperSlots[0][0] = brick
		return

	_connectToBrickXm: (brick, x, y, z, grid) =>
		if x > 0 and grid.zLayers[z]?[x - 1]?[y]? and
		grid.zLayers[z][x - 1][y] != false
			brick.neighbours[0] = [grid.zLayers[z][x - 1][y].brick]
			grid.zLayers[z][x - 1][y].brick.neighbours[1] = [brick]
		return

	_connectToBrickYm: (brick, x, y, z, grid) =>
		if y > 0 and grid.zLayers[z]?[x]?[y - 1]? and
		grid.zLayers[z][x][y - 1] != false
			brick.neighbours[2] = [grid.zLayers[z][x][y - 1].brick]
			grid.zLayers[z][x][y - 1].brick.neighbours[3] = [brick]
		return

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
		maxNumRandomChoicesWithoutMerge = numTotalInitialBricks / 2

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

		if mergeIndex == 1
			position = brick.position
			size = {
				x: brick.size.x + mergeNeighbours[0].size.x
				y: brick.size.y
				z: brick.size.z
			}
		else if mergeIndex == 0
			position = {
				x: mergeNeighbours[0].position.x
				y: brick.position.y
				z: brick.position.z
			}
			size = {
				x: brick.size.x + mergeNeighbours[0].size.x
				y: brick.size.y
				z: brick.size.z
			}
		else if mergeIndex == 3
			position = brick.position
			size = {
				x: brick.size.x
				y: brick.size.y + mergeNeighbours[0].size.y
				z: brick.size.z
			}
		else if mergeIndex == 2
			position = {
				x: brick.position.x
				y: mergeNeighbours[0].position.y
				z: brick.position.z
			}
			size = {
				x: brick.size.x
				y: brick.size.y + mergeNeighbours[0].size.y
				z: brick.size.z
			}

		newBrick = new Brick(position, size)
		newBrick.id = @nextBrickIdx()

		# setting new neighbours
		ids = @_neighbourMergeIndices(mergeIndex)
		old = mergeNeighbours.concat [brick, newBrick]

		@_updateNeighbours newBrick, brick, ids.opposite, mergeIndex, old
		@_updateNeighbours newBrick, brick, ids.sides[0], ids.sides[1], old
		@_updateNeighbours newBrick, brick, ids.sides[1], ids.sides[0], old
		for mergeBrick in mergeNeighbours
			@_updateNeighbours newBrick, mergeBrick, mergeIndex, ids.opposite, old
			@_updateNeighbours newBrick, mergeBrick, ids.sides[0], ids.sides[1], old
			@_updateNeighbours newBrick, mergeBrick, ids.sides[1], ids.sides[0], old

		# set new brick connections
		for mbrick in mergeNeighbours.concat [brick]
			newBrick.getConnectionsFromMergingBrick mbrick

		# delete outdated bricks from bricks array
		z = brick.position.z
		@_removeFirstOccurenceFromArray brick, bricks[z]
		for neighbour in mergeNeighbours
			@_removeFirstOccurenceFromArray neighbour, bricks[z]

		# add newBrick to bricks array
		bricks[z].push newBrick

		###
		console.log 'MERGE'
		console.log mergeIndex
		console.log brick
		console.log mergeNeighbours
		console.log newBrick
		###
		return newBrick

	_findWeakArticulationPointsInGraph: (bricks) =>
		return

	_updateNeighbours: (newBrick, oldBrick, dir, opp, oldBricks) =>
		for neighbour in oldBrick.neighbours[dir]
			if neighbour not in oldBricks
				if neighbour.id < newBrick.id
					newBrick.neighbours[dir].push neighbour
					neighbour.neighbours[opp].push newBrick
			@_removeFirstOccurenceFromArray oldBrick, neighbour.neighbours[opp]
		return

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
