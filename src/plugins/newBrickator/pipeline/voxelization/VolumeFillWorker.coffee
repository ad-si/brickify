module.exports =
	fillGrid: (grid, callback) ->
		numVoxelsX = grid.length - 1
		numVoxelsY = 0
		numVoxelsZ = 0
		for x, voxelPlane of grid
			numVoxelsY = Math.max numVoxelsY, voxelPlane.length - 1
			for y, voxelColumn of voxelPlane
				numVoxelsZ = Math.max numVoxelsZ, voxelColumn.length - 1

		@_resetProgress()

		for x, voxelPlane of grid
			x = parseInt x
			for y, voxelColumn of voxelPlane
				y = parseInt y
				@_postProgress callback, x, y, numVoxelsX, numVoxelsY
				@_fillUp grid, x, y, numVoxelsZ
		callback state: 'finished', data: grid

	#_fillUp: (grid, x, y, numVoxelsZ)

	_fillUp: (grid, x, y, numVoxelsZ) ->
	# fill up from z=0 to z=max
		insideModel = false
		z = 0
		currentFillVoxelQueue = []

		while z <= numVoxelsZ
			if grid[x][y][z]?
	# current voxel already exists (shell voxel)
				dir = grid[x][y][z].dir

				@_setVoxels grid, x, y, currentFillVoxelQueue, 0

				if dir > 0
	# leaving model
					insideModel = false
				else if dir < 0
	# entering model
					insideModel = true
			else
	# voxel does not exist yet. create if inside model
				if insideModel
					currentFillVoxelQueue.push z
			z++
		return

	_setVoxels: (grid, x, y, zValues, voxelData) ->
		while zValue = zValues.pop()
			@_setVoxel grid, x, y, zValue, voxelData

	_setVoxel: (grid, x, y, z, voxelData) ->
		grid[x] ?= []
		grid[x][y] ?= []
		grid[x][y][z] ?= []
		grid[x][y][z] = voxelData

	_resetProgress: ->
		@lastProgress = -1

	_postProgress: (callback, x, y, numVoxelsX, numVoxelsY) ->
		progress = Math.round(
			100 * ((x - 1) * numVoxelsY + y - 1) / numVoxelsX / numVoxelsY)
		return unless progress > @lastProgress
		@lastProgress = progress
		callback state: 'progress', progress: progress
