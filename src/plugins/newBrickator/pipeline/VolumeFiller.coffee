Grid = require './Grid'

module.exports = class VolumeFiller
	fillGrid: (grid, options) ->
		# fills spaces in the grid. Goes up from z=0 to z=max and looks for
		# voxels facing downwards (start filling), stops when it sees voxels
		# facing upwards

		gridPOJO = grid.toPOJO()
		numVoxelsZ = grid.getNumVoxelsZ()
		@worker = @getWorker()
		return @worker.fillGrid gridPOJO, numVoxelsZ
		.then (newGridPOJO) =>
			@worker.terminate()
			@worker = null
			newGrid = new Grid grid.spacing
			newGrid.origin = grid.origin
			newGrid.fromPojo newGridPOJO
			return {grid: newGrid}

	terminate: =>
		@worker?.terminate()
		@worker = null

	getWorker: ->
		operative {
			fillGrid: (grid, numVoxelsZ) ->
				for x, voxelPlane of grid
					for y, voxelColumn of voxelPlane
						@fillUp grid, x, y, numVoxelsZ
				@deferred().fulfill grid

			fillUp: (grid, x, y, numVoxelsZ) ->
				#fill up from z=0 to z=max
				insideModel = false
				z = 0
				currentFillVoxelQueue = []

				while z < numVoxelsZ
					if grid[x][y][z]?
						# current voxel already exists (shell voxel)
						dir = @calculateVoxelDirection grid, x, y, z

						if dir.definitelyUp
							#fill up voxels and leave model
							for v in currentFillVoxelQueue
								@setVoxel grid, v, {inside: true}
							insideModel = false
						else if dir.definitelyDown
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

			calculateVoxelDirection: (grid, x, y, z, tolerance = 0.1) ->
				# determines whether all polygons related to this voxel are either
				# all aligned upwards or all aligned downwards
				dataEntrys = grid[x][y][z]
				numUp = 0
				numDown = 0

				for e in dataEntrys
					# everything smaller than tolerance is considered level
					if e.dZ > tolerance then numUp++ else if e.dZ < -tolerance then numDown++

				if numUp > 0 and numDown == 0
					definitelyUp = true
				else
					definitelyUp = false

				if numDown > 0 and numUp == 0
					definitelyDown = true
				else
					definitelyDown = false

				dataEntrys.definitelyUp = definitelyUp
				dataEntrys.definitelyDown = definitelyDown

				return {
				definitelyUp: definitelyUp
				definitelyDown: definitelyDown
				}

			setVoxel: (grid, {x: x, y: y, z: z}, voxelData) ->
				grid[x] ?= []
				grid[x][y] ?= []
				grid[x][y][z] ?= []
				grid[x][y][z].push voxelData
			}
