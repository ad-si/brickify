Grid = require './Grid'

module.exports = class Voxelizer
	constructor: ->
		@voxelGrid = null

	_addDefaults: (options) ->
		options.lineAccuracy ?= 16
		options.outerAccuracy ?= 5
		options.zTolerance ?= 0.1

	voxelize: (optimizedModel, options = {}, progressCallback) =>
		@_addDefaults options
		@setupGrid optimizedModel, options

		lineStepSize = @voxelGrid.heightRatio / options.lineAccuracy
		outerStepSize = @voxelGrid.heightRatio / options.outerAccuracy

		voxelSpaceModel = @_getOptimizedVoxelSpaceModel optimizedModel, options

		@worker = @_getWorker()
		@worker.voxelize voxelSpaceModel, lineStepSize, outerStepSize, (message) =>
			if message.state is 'progress'
				progressCallback message.progress
			else # if state is 'finished'
				@resolve grid: @voxelGrid, gridPOJO: message.data

		return new Promise (@resolve, reject) => return

	terminate: =>
		@worker?.terminate()
		@worker = null

	_getOptimizedVoxelSpaceModel: (optimizedModel, options) =>
		positions = optimizedModel.positions
		voxelSpacePositions = []
		for i in [0...positions.length] by 3
			position =
				x: positions[i]
				y: positions[i + 1]
				z: positions[i + 2]
			position = @voxelGrid.mapModelToVoxelSpace position
			voxelSpacePositions.push position.x
			voxelSpacePositions.push position.y
			voxelSpacePositions.push position.z

		normals = optimizedModel.faceNormals
		directions = []
		for i in [2...normals.length] by 3
			z = normals[i]
			directions.push @_getTolerantDirection z, options.zTolerance

		return {
			positions: voxelSpacePositions
			indices: optimizedModel.indices
			directions: directions
		}

	_getWorker: ->
		return @worker if @worker?
		return operative {
			voxelize: (model, lineStepSize, outerStepSize, progressCallback) ->
				grid = []
				@_resetProgress()
				@_forEachPolygon model, (p0, p1, p2, direction, progress) ->
					@_voxelizePolygon(
						p0
						p1
						p2
						direction
						lineStepSize
						outerStepSize
						grid
					)
					@_postProgress(progress, progressCallback)
				progressCallback state: 'finished', data: grid

			_voxelizePolygon: (p0, p1, p2, dZ, lineStepSize, outerStepSize, grid) ->
				# transform model coordinates to voxel coordinates
				# (object may be moved/rotated)

				#store information for filling solids
				direction = dZ

				l0len = @_getLength p0, p1
				l1len = @_getLength p1, p2
				l2len = @_getLength p2, p0

				#sort for short and long side
				if l0len >= l1len and l0len >= l2len
					longSide = {start: p0, end: p1}
					shortSide1 = {start: p1, end: p2}
					shortSide2 = {start: p2, end: p0}

					shortSideLength1 = l1len
					shortSideLength2 = l2len
				else if l1len >= l0len and l1len >= l2len
					longSide = {start: p1, end: p2}
					shortSide1 = {start: p1, end: p0}
					shortSide2 = {start: p0, end: p2}

					shortSideLength1 = l0len
					shortSideLength2 = l2len
				else # if l2len >= l0len and l2len >= l1len
					longSide = {start: p2, end: p0}
					shortSide1 = {start: p2, end: p1}
					shortSide2 = {start: p1, end: p0}

					shortSideLength1 = l1len
					shortSideLength2 = l0len

				longSideStepSize = 1 / (shortSideLength1 + shortSideLength2) * outerStepSize

				longSideIndex = 0

				for i in [0..1] by outerStepSize / shortSideLength1
					p0 = @_interpolateLine shortSide1, i
					p1 = @_interpolateLine longSide, longSideIndex
					longSideIndex += longSideStepSize
					@_voxelizeLine p0, p1, direction, lineStepSize, grid

				for i in [0..1] by outerStepSize / shortSideLength2
					p0 = @_interpolateLine shortSide2, i
					p1 = @_interpolateLine longSide, longSideIndex
					longSideIndex += longSideStepSize
					@_voxelizeLine p0, p1, direction, lineStepSize, grid

			_getLength: ({x: x1, y: y1, z: z1}, {x: x2, y: y2, z: z2}) ->
				dx = x2 - x1
				dy = y2 - y1
				dz = z2 - z1
				return Math.sqrt dx * dx + dy * dy + dz * dz

			_interpolateLine: ({start: {x: x1, y: y1, z: z1},
			end: {x: x2, y: y2, z: z2}}, i) ->
				i = Math.min i, 1.0
				x = x1 + (x2 - x1) * i
				y = y1 + (y2 - y1) * i
				z = z1 + (z2 - z1) * i
				return x: x, y: y, z: z

			###
			# Voxelizes the line from a to b. Stores data in each generated voxel.
			#
			# @param a point the start point of the line
			# @param b point the end point of the line
			# @param voxelData Object data to store in the voxel grid for each voxel
			# @param stepSize Number the stepSize to use for sampling the line
			###
			_voxelizeLine: (a, b, direction, stepSize, grid) ->
				length = @_getLength a, b
				dx = (b.x - a.x) / length * stepSize
				dy = (b.y - a.y) / length * stepSize
				dz = (b.z - a.z) / length * stepSize

				currentVoxel = x: 0, y: 0, z: -1 # not a valid voxel because of z < 0
				currentGridPosition = x: a.x, y: a.y, z: a.z

				for i in [0..length] by stepSize
					oldVoxel = currentVoxel
					currentVoxel = @_roundVoxelSpaceToVoxel currentGridPosition
					if (oldVoxel.x != currentVoxel.x) or
					(oldVoxel.y != currentVoxel.y) or
					(oldVoxel.z != currentVoxel.z)
						@_setVoxel currentVoxel, direction, grid
					currentGridPosition.x += dx
					currentGridPosition.y += dy
					currentGridPosition.z += dz

			_roundVoxelSpaceToVoxel: ({x: x, y: y, z: z}) ->
				return {
					x: Math.round x
					y: Math.round y
					z: Math.round z
				}

			_setVoxel: ({x: x, y: y, z: z}, direction, grid) ->
				grid[x] ?= []
				grid[x][y] ?= []
				oldDirection = grid[x][y][z]
				if oldDirection? and direction isnt 0
					grid[x][y][z] = 0 unless oldDirection is direction
				else
					grid[x][y][z] = direction

			_resetProgress: ->
				@lastProgress = -1

			_postProgress: (progressFloat, callback) ->
				currentProgress = Math.round 100 * progressFloat
				# only send progress updates in 1% steps
				return unless currentProgress > @lastProgress
				@lastProgress = currentProgress
				callback state: 'progress', progress: currentProgress

			_forEachPolygon: (model, visitor) ->
				indices = model.indices
				positions = model.positions
				directions = model.directions
				length = directions.length
				for i in [0...length]
					i3 = i * 3
					p0 = {
						x: positions[indices[i3] * 3]
						y: positions[indices[i3] * 3 + 1]
						z: positions[indices[i3] * 3 + 2]
					}
					p1 = {
						x: positions[indices[i3 + 1] * 3]
						y: positions[indices[i3 + 1] * 3 + 1]
						z: positions[indices[i3 + 1] * 3 + 2]
					}
					p2 = {
						x: positions[indices[i3 + 2] * 3]
						y: positions[indices[i3 + 2] * 3 + 1]
						z: positions[indices[i3 + 2] * 3 + 2]
					}
					direction = directions[i]

					visitor p0, p1, p2, direction, i / length
		}

	_getTolerantDirection: (dZ, tolerance) ->
		return if dZ > tolerance then 1 else if dZ < -tolerance then -1 else 0

	setupGrid: (optimizedModel, options) ->
		@voxelGrid = new Grid(options.gridSpacing)
		@voxelGrid.setUpForModel optimizedModel, options
		return @voxelGrid
