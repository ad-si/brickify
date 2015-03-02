module.exports = class Brick
	@_nextBrickIndex = 0

	# to replace magic numbers when using the @neighbours[] array
	@direction = {
		Xm: 0
		Xp: 1
		Ym: 2
		Yp: 3
	}

	@getNextBrickIndex: () =>
		return @_nextBrickIndex++

	constructor: (@position, @size) ->
		# position always contains smallest x & smallest y

		#initialize slots
		@upperSlots = []
		@lowerSlots = []
		@id = Brick.getNextBrickIndex()

		#save old bricks for debugging, false = none, otherwise [] with bricks
		@mergedNeighbours = false
		@mergedBrick = false

		for xx in [0..@size.x - 1] by 1
			@upperSlots[xx] = []
			@lowerSlots[xx] = []
			for yy in [0..@size.y - 1] by 1
				@upperSlots[xx][yy] = false
				@lowerSlots[xx][yy] = false

		# x-, x+, y-, y+
		@neighbours = [[], [], [], []]
		return

	@availableBrickSizes: () =>
		return [
			[1, 1, 1], [1, 2, 1], [1, 3, 1], [1, 4, 1], [1, 6, 1], [1, 8, 1],
			[2, 2, 1], [2, 3, 1], [2, 4, 1], [2, 6, 1], [2, 8, 1], [2, 10, 1],
			[1, 1, 3], [1, 2, 3], [1, 3, 3], [1, 4, 3],
			[1, 6, 3], [1, 8, 3], [1, 10, 3], [1, 12, 3], [1, 16, 3]
			[2, 2, 3], [2, 3, 3], [2, 4, 3], [2, 6, 3], [2, 8, 3], [2, 10, 3]
		]

	# Removes references to this brick from this brick's neighbours/connections
	removeSelfFromSurrounding: () =>
		# delete from connected and neighbour bricks
		connectedBricks = @uniqueNeighbours()
		connectedBricks = connectedBricks.concat @uniqueConnectedBricks()

		for connectedBrick in connectedBricks
			connectedBrick.clearReferenceTo @

	# Removes all references to the brickToBeRemoved from this brick
	clearReferenceTo: (brickToBeRemoved) =>
		for xi in [0...@size.x]
			for yi in [0...@size.y]
				if @upperSlots[xi][yi] == brickToBeRemoved
					@upperSlots[xi][yi] = false
				if @lowerSlots[xi][yi] == brickToBeRemoved
					@lowerSlots[xi][yi] = false

		for i in [0...@neighbours.length]
			brickIndex = @neighbours[i].indexOf(brickToBeRemoved)
			if brickIndex >= 0
				@neighbours[i].splice(brickIndex,1)

	uniqueConnectedBricks: () =>
		upperBricks = Brick.uniqueBricksInSlots @upperSlots
		lowerBricks = Brick.uniqueBricksInSlots @lowerSlots
		return upperBricks.concat lowerBricks

	@uniqueBricksInSlots: (upperOrLowerSlots) =>
		bricks = []
		for slotsX in upperOrLowerSlots
			for slotXY in slotsX
				if slotXY != false
					bricks.push slotXY
		return removeDuplicates bricks

	uniqueNeighbours: () =>
		neighboursList = [].concat.apply([],@neighbours)
		return neighboursList

	@isValidSize: (width, length, height) =>
		for validSize in Brick.availableBrickSizes()
			if validSize[0] == width and validSize[1] == length and
			validSize[2] == height
				return true
			if validSize[0] == length and validSize[1] == width and
			validSize[2] == height
				return true
		return false

	# helper method, to be moved somewhere more appropriate
	removeDuplicates = (array) ->
		a = array.concat()
		i = 0

		while i < a.length
			j = i + 1
			while j < a.length
				a.splice j--, 1	if a[i] is a[j]
				++j
			++i
		return a

	getConnectionsFromMergingBrick: (mBrick) =>
		self = @
		offsetXY = {
			x: mBrick.position.x - @position.x
			y: mBrick.position.y - @position.y
		}

		for slots, x in mBrick.upperSlots
			for slot, y in slots
				if slot != false
					self.upperSlots[offsetXY.x + x][offsetXY.y + y] = slot
					offsetInConBrick = {
						x: (self.position.x + offsetXY.x + x) - slot.position.x
						y: (self.position.y + offsetXY.y + y) - slot.position.y
					}
					slot.lowerSlots[offsetInConBrick.x][offsetInConBrick.y] = self

		for slots, x in mBrick.lowerSlots
			for slot, y in slots
				if slot != false
					self.lowerSlots[offsetXY.x + x][offsetXY.y + y] = slot
					offsetInConBrick = {
						x: (self.position.x + offsetXY.x + x) - slot.position.x
						y: (self.position.y + offsetXY.y + y) - slot.position.y
					}
					slot.upperSlots[offsetInConBrick.x][offsetInConBrick.y] = self

		return

	getNeighboursFromMergingBrick: (mBrick) =>
		#check all four directions
		if @position.x == mBrick.position.x
			#take neighbour in direction 0 xm
			@_replaceOldNeighbours mBrick, Brick.direction.Xm, Brick.direction.Xp
		if @position.y == mBrick.position.y
			#take neighbour in direction 2 ym
			@_replaceOldNeighbours mBrick, Brick.direction.Ym, Brick.direction.Yp
		if (@position.x + @size.x) == (mBrick.position.x + mBrick.size.x)
			#take neighbour in direction 1 xp
			@_replaceOldNeighbours mBrick, Brick.direction.Xp, Brick.direction.Xm
		if (@position.y + @size.y) == (mBrick.position.y + mBrick.size.y)
			#take neighbour in direction 3 yp
			@_replaceOldNeighbours mBrick, Brick.direction.Yp, Brick.direction.Ym

	_replaceOldNeighbours: (mBrick, dir, opp) =>
		for neighbour in mBrick.neighbours[dir]
			@neighbours[dir].push neighbour
			@_removeFirstOccurenceFromArray mBrick, neighbour.neighbours[opp]
			neighbour.neighbours[opp].push @
		return

	getPositionAndSizeForNewBrick: (mergeIndex, mergeNeighbours) =>
		if mergeIndex == 1
			position = @position
			size = {
				x: @size.x + mergeNeighbours[0].size.x
				y: @size.y
				z: @size.z
			}
		else if mergeIndex == 0
			position = {
				x: mergeNeighbours[0].position.x
				y: @position.y
				z: @position.z
			}
			size = {
				x: @size.x + mergeNeighbours[0].size.x
				y: @size.y
				z: @size.z
			}
		else if mergeIndex == 3
			position = @position
			size = {
				x: @size.x
				y: @size.y + mergeNeighbours[0].size.y
				z: @size.z
			}
		else if mergeIndex == 2
			position = {
				x: @position.x
				y: mergeNeighbours[0].position.y
				z: @position.z
			}
			size = {
				x: @size.x
				y: @size.y + mergeNeighbours[0].size.y
				z: @size.z
			}

		return {position: position, size: size}

	_removeFirstOccurenceFromArray: (object, array) =>
		i = array.indexOf object
		if i != -1
			array.splice i, 1
		return

	split: () =>
		newBricks = []
		for x in [0..@size.x - 1] by 1
			newBricks[x] = []
			for y in [0..@size.y - 1] by 1
				newBricks[x][y] = false

		for x in [0..@size.x - 1]
			for y in [0..@size.y - 1]
				newPosition = {
					x: @position.x + x
					y: @position.y + y
					z: @position.z
				}
				newBricks[x][y] = new Brick(newPosition,{x: 1, y: 1, z: 1})

				# update connections
				if @upperSlots[x][y] != false
					connectedBrick = @upperSlots[x][y]
					newBricks[x][y].upperSlots[0][0] = connectedBrick
					offsetInConBrick = {
						x: (newBricks[x][y].position.x) - connectedBrick.position.x
						y: (newBricks[x][y].position.y) - connectedBrick.position.y
					}
					connectedBrick.lowerSlots[offsetInConBrick.x][offsetInConBrick.y] =
						newBricks[x][y]

				if @lowerSlots[x][y] != false
					connectedBrick = @lowerSlots[x][y]
					newBricks[x][y].lowerSlots[0][0] = connectedBrick
					offsetInConBrick = {
						x: (newBricks[x][y].position.x) - connectedBrick.position.x
						y: (newBricks[x][y].position.y) - connectedBrick.position.y
					}
					connectedBrick.upperSlots[offsetInConBrick.x][offsetInConBrick.y] =
						newBricks[x][y]

				# update neighbours outside of splitting brick
				if newBricks[x][y].position.x == @position.x
					#take neighbour in direction 0 xm
					@addNeighboursToNewBrick newBricks[x][y],
					Brick.direction.Xm, Brick.direction.Xp
				if newBricks[x][y].position.y == @position.y
					#take neighbour in direction 2 ym
					@addNeighboursToNewBrick newBricks[x][y],
					Brick.direction.Ym, Brick.direction.Yp
				if (newBricks[x][y].position.x + newBricks[x][y].size.x) ==
				(@position.x + @size.x)
					#take neighbour in direction 1 xp
					@addNeighboursToNewBrick newBricks[x][y],
					Brick.direction.Xp, Brick.direction.Xm
				if (newBricks[x][y].position.y + newBricks[x][y].size.y) ==
				(@position.y + @size.y)
					#take neighbour in direction 3 yp
					@addNeighboursToNewBrick newBricks[x][y],
					Brick.direction.Yp, Brick.direction.Ym

				# update neighbours inside the splitting brick
				if x > 0
					newBricks[x][y].neighbours[Brick.direction.Xm].push newBricks[x - 1][y]
					newBricks[x - 1][y].neighbours[Brick.direction.Xp].push newBricks[x][y]
				if y > 0
					newBricks[x][y].neighbours[Brick.direction.Ym].push newBricks[x][y - 1]
					newBricks[x][y - 1].neighbours[Brick.direction.Yp].push newBricks[x][y]

		#remove this (old) brick from all neighbours
		for neighbours in @neighbours
			for neighbour in neighbours
				for i in [0..3] by 1
					@_removeFirstOccurenceFromArray @, neighbour.neighbours[i]

		return [].concat.apply([], newBricks)

	addNeighboursToNewBrick: (newBrick, direction, opposite) =>
		if direction in [Brick.direction.Xm,Brick.direction.Xp]
			minY = newBrick.position.y
			maxY = newBrick.position.y + newBrick.size.y
			for neighbour in @neighbours[direction]
				if neighbour.position.y <= minY and
				neighbour.position.y + neighbour.size.y >= maxY
					newBrick.neighbours[direction].push neighbour
					neighbour.neighbours[opposite].push newBrick

		if direction in [Brick.direction.Ym, Brick.direction.Yp]
			minX = newBrick.position.x
			maxX = newBrick.position.x + newBrick.size.x
			for neighbour in @neighbours[direction]
				if neighbour.position.x <= minX and
				neighbour.position.x + neighbour.size.x >= maxX
					newBrick.neighbours[direction].push neighbour
					neighbour.neighbours[opposite].push newBrick

		return

	getStability: () =>
		# possible links at top and bottom
		possibleLinks = 2 * @size.x * @size.y
		links = 0
		for x in [0..@size.x - 1]
			for y in [0..@size.y - 1]
				if @upperSlots[x][y] != false
					links++
				if @lowerSlots[x][y] != false
					links++
		return links / possibleLinks

