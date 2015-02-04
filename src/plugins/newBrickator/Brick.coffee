module.exports = class Brick
	constructor: (@position, @size) ->
		# position always contains smalles x & smallest y

		#initialize slots
		@upperSlots = []
		@lowerSlots = []
		@id = -1

		for xx in [0..@size.x - 1] by 1
			@upperSlots[xx] = []
			@lowerSlots[xx] = []
			for yy in [0..@size.y - 1] by 1
				@upperSlots[xx][yy] = false
				@lowerSlots[xx][yy] = false

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
		return Brick.removeDuplicates bricks

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
	@removeDuplicates = (array) ->
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
			@_replaceOldNeighbours mBrick, 0, 1
		if @position.y == mBrick.position.y
			#take neighbour in direction 2 ym
			@_replaceOldNeighbours mBrick, 2, 3
		if (@position.x + @size.x) == (mBrick.position.x + mBrick.size.x)
			#take neighbour in direction 1 xp
			@_replaceOldNeighbours mBrick, 1, 0
		if (@position.y + @size.y) == (mBrick.position.y + mBrick.size.y)
			#take neighbour in direction 3 yp
			@_replaceOldNeighbours mBrick, 3, 2

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
