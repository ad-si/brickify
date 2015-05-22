Grid = require './Grid'

module.exports = class VolumeFiller
	fillGrid: (grid, options, progressCallback) ->
		# fills spaces in the grid. Goes up from z=0 to z=max and looks for
		# voxels facing downwards (start filling), stops when it sees voxels
		# facing upwards

		gridPOJO = grid.toPOJO()

		callback = (message) =>
			if message.state is 'progress'
				progressCallback message.progress
			else # if state is 'finished'
				@terminate()
				newGrid = new Grid grid.spacing
				newGrid.origin = grid.origin
				newGrid.fromPojo message.data
				@resolve newGrid

		numVoxelsX = grid.getNumVoxelsX()
		numVoxelsY = grid.getNumVoxelsY()
		numVoxelsZ = grid.getNumVoxelsZ()
		@worker = @getWorker()
		@worker.fillGrid(
			gridPOJO
			numVoxelsX
			numVoxelsY
			numVoxelsZ
			callback
		)

		return new Promise (@resolve, reject) => return

	terminate: =>
		@worker?.terminate()
		@worker = null

	getWorker: ->
		return operative {
			fillGrid: (grid, numVoxelsX, numVoxelsY, numVoxelsZ, callback) ->
				for x, voxelPlane of grid
					for y, voxelColumn of voxelPlane
						x = parseInt x
						y = parseInt y
						@fillUp grid, x, y, numVoxelsZ
						@updateProgress callback, x, y, numVoxelsX, numVoxelsY
				callback state: 'finished', data: grid

			fillUp: (grid, x, y, numVoxelsZ) ->
				#fill up from z=0 to z=max
				insideModel = false
				z = 0
				currentFillVoxelQueue = []

				while z < numVoxelsZ
					if grid[x][y][z]?
						# current voxel already exists (shell voxel)
						dir = grid[x][y][z]

						if dir > 0
							#fill up voxels and leave model
							for v in currentFillVoxelQueue
								@setVoxel grid, v, {inside: true}
							insideModel = false
						else if dir < 0
							# re-entering model if inside? that seems odd. empty current fill queue
							if insideModel
								currentFillVoxelQueue = []
							#entering model
							insideModel = true
						else
							#if not sure, fill up (precautious people might leave this out?)
							for v in currentFillVoxelQueue
								@setVoxel grid, v, {inside: true}
							currentFillVoxelQueue = []

							insideModel = false
					else
						#voxel does not yet exist. create if inside model
						if insideModel
							currentFillVoxelQueue.push {x: x, y: y, z: z}
					z++

			setVoxel: (grid, {x: x, y: y, z: z}, voxelData) ->
				grid[x] ?= []
				grid[x][y] ?= []
				grid[x][y][z] ?= []
				grid[x][y][z].push voxelData

			updateProgress: (callback, x, y, numVoxelsX, numVoxelsY) ->
				progress = ((x - 1) * numVoxelsY + y - 1) / numVoxelsX / numVoxelsY
				callback state: 'progress', progress: progress

		}
