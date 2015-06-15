Grid = require './Grid'

module.exports = class VolumeFiller
	fillGrid: (grid, gridPOJO, options, progressCallback) ->
		# fills spaces in the grid. Goes up from z=0 to z=max and looks for
		# voxels facing downwards (start filling), stops when it sees voxels
		# facing upwards

		callback = (message) =>
			if message.state is 'progress'
				progressCallback message.progress
			else # if state is 'finished'
				grid.fromPojo message.data
				@resolve grid: grid

		@worker = @_getWorker()
		@worker.fillGrid(
			gridPOJO
			callback
		)

		return new Promise (@resolve, reject) => return

	terminate: =>
		@worker?.terminate()
		@worker = null

	_getWorker: ->
		return @worker if @worker?
		return operative {
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

						if dir is 1
							# fill up voxels and leave model
							@_setVoxels grid, x, y, currentFillVoxelQueue, 0
							insideModel = false
						else if dir is -1
							# entering model
							currentFillVoxelQueue = []
							insideModel = true
						else
							currentFillVoxelQueue = []
					else
						# voxel does not exist yet. create if inside model
						if insideModel
							currentFillVoxelQueue.push z
					z++
				return

			_setVoxels: (grid, x, y, zs, voxelData) ->
				for z in zs
					@_setVoxel grid, x, y, z, voxelData

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
		}
