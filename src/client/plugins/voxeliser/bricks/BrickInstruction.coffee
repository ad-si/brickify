class BrickInstruction
	
	constructor: (@layout, @mode) ->
		@blockSize = 3

		@index = 0
		@nextBlockIdx = 0
		@sortedBricks = []

		# Will store to @sortedBricks
		switch @mode
			when InstrutionMode.layerwise then @storeBricksLayerwise()
			when InstrutionMode.blockwise then @storeBricksBlockwise()
			when InstrutionMode.treewise then @storeBricksTreewise()

		@numBlocks = @sortedBricks.length

	getState: ->
		return {'isFirstBlock': @isFirstBlock, 'isLastBlock': @isLastBlock}

	is_first_Step: () ->
		@index == 0

	is_last_Step: () ->
		@index > @numBlocks

	get_Step_of: (index) ->
		index = index - 1
		if index < 0 or index >= @numBlocks
			return null
		return @sortedBricks[index]

	next_Step: () ->
		if @.is_last_Step()
			return null
		@.get_Step_of @index++

	previous_Step: () ->
		if @.is_first_Step()
			return null
		@.get_Step_of @index--

	# -----------
	# Treewise
	# -----------
	storeBricksTreewise: ->

		check_Deadlock = (brick, construction, layout) ->
			x = brick.position.x
			y = brick.position.y
			
			ex = brick.extend.x
			ey = brick.extend.y

			z = brick.position.z

			grid = layout.grid

			deadlock = no


			for dx in [0...ex]
				for dy in [0...ey]
					stop = no
					for dz in [0...z].reverse()
						lowBrick = grid[ex + x][ey + y][dz]
						if not lowBrick
							stop = yes
						if construction.includes lowBrick and not stop
							deadlock = yes
					stop = no
					for dz in [layout.extend.z...z].reverse()
						upBrick = grid[ex + x][ey + y][dz]
						if not upBrick
							stop = yes
						if construction.includes upBrick and not stop
							deadlock = yes


			#deadlock = no
			#for upbrick in brick.get_upper_connected_Bricks()
			#  for buildBrick in construction
			#    if buildBrick.get_lower_connected_Bricks().includes upbrick
			#      unless construction.includes upbrick
			#        deadlock = yes
			#for lowbrick in brick.get_lower_connected_Bricks()
			#  for buildBrick in construction
			#    if buildBrick.get_upper_connected_Bricks().includes lowbrick
			#      unless construction.includes lowbrick
			#        deadlock = yes
						
			deadlock

		layers = @.storeBricksLayerwise()
		@sortedBricks = []

		ml = (layers.length - (layers.length % 2)) / 2
		first_brick = layers[ml].pop()

		done_bricks = [first_brick]
		next_bricks = first_brick.get_connected_Bricks()

		while next_bricks.length > 0
			next_brick = next_bricks.shift()
			unless done_bricks.includes next_brick
				if check_Deadlock next_brick, done_bricks, @layout
					next_bricks.add next_brick
				else
					for connection in next_brick.get_connected_Bricks()
						next_bricks.add_unique connection unless done_bricks.includes connection
					done_bricks.add next_brick

		@sortedBricks = []

		brickbag = []
		for brick in done_bricks
			if brickbag.length == @blockSize
				@sortedBricks.add brickbag
				brickbag = []
			brickbag.add brick
		 
		@sortedBricks.add brickbag if brickbag.length > 0
		@sortedBricks

		###bricks = [] # used to mark
		while bricks.length != @layout.get_BrickCount()
			# find a first brick
			firstBrick = null
			for b in @layout.getAllBricks()
				if bricks.indexOf(b) == -1
					firstBrick = b
					break
			if not firstBrick?
				console.log "ERROR: No valid brick in tree could be found"

			# Breadth-first search algorithm
			bricks.push(firstBrick)
			visitNeeded = [] # used as a queue for traversal
			visitNeeded.push(firstBrick)

			while visitNeeded.length > 0
				brick = visitNeeded.pop() # pop the traversal queue
				conns = getConnectedBricks(brick)
				for b in conns
					if bricks.indexOf(b) == -1 # if not marked
						bricks.push(b) # mark
						visitNeeded.push(b) # enqueue

			createBlocks(bricks)
		###

	# -----------
	# BLOCKWISE
	# -----------
	storeBricksBlockwise: ->
		layers = @.storeBricksLayerwise()
		@sortedBricks = []

		brickbag = []
		for layer in layers
			for brick in layer
				if brickbag.length == @blockSize
					@sortedBricks.add brickbag
					brickbag = []
				brickbag.add brick
		 
		@sortedBricks.add brickbag if brickbag.length > 0
		@sortedBricks

	# -----------
	# LAYERWISE
	# -----------
	storeBricksLayerwise: ->
		@sortedBricks = []

		for layerId in [0...@layout.extend.z]
			@sortedBricks.add @layout.get_BricksOfLayer(layerId)

		handled_Bricks = []
		for layer in @sortedBricks
			for brick in layer.clone()
				if handled_Bricks.includes brick
					layer.remove brick
				else
					handled_Bricks.add brick

		for layer in @sortedBricks.clone()
			@sortedBricks.remove layer unless layer.is_not_empty()

		@sortedBricks

	# -----------
	# Helper
	# -----------
	createBlocks: (bricks) ->
		@sortedBricks = []

		brickBlock = []
		for brick, i in bricks
			brickBlock.push brick
			if i % @blockSize == 0
				@sortedBricks.push brickBlock
				brickBlock = []

		if brickBlock.length > 0
			@sortedBricks.push brickBlock

module.exports = BrickInstruction
