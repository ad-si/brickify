Grid = require './Grid'

floatDelta = 1e-10
voxelRoundingThreshold = 1e-5

module.exports = class Voxelizer
	constructor: ->
		@voxelGrid = null

	_addDefaults: (options) ->
		options.accuracy ?= 16
		options.zTolerance ?= 0.01

	voxelize: (optimizedModel, options = {}, progressCallback) =>
		@_addDefaults options
		@setupGrid optimizedModel, options

		lineStepSize = @voxelGrid.heightRatio / options.accuracy

		voxelSpaceModel = @_getOptimizedVoxelSpaceModel optimizedModel, options

		callback = (message) =>
			if message.state is 'progress'
				progressCallback message.progress
			else # if state is 'finished'
				@resolve grid: @voxelGrid, gridPOJO: message.data

		@worker = @_getWorker()
		@worker.voxelize(
			voxelSpaceModel
			lineStepSize
			floatDelta
			voxelRoundingThreshold
			callback
		)

		return new Promise (@resolve, reject) => return

	terminate: =>
		@worker?.terminate()
		@worker = null

	_getOptimizedVoxelSpaceModel: (optimizedModel, options) =>
		positions = optimizedModel.positions
		voxelSpacePositions = new Array positions.length
		for i in [0...positions.length] by 3
			position =
				x: positions[i]
				y: positions[i + 1]
				z: positions[i + 2]
			position = @voxelGrid.mapModelToVoxelSpace position
			voxelSpacePositions[i] = position.x
			voxelSpacePositions[i + 1] = position.y
			voxelSpacePositions[i + 2] = position.z

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
			voxelize: (model, lineStepSize, @floatDelta, @voxelRoundingThreshold,
			progressCallback) ->
				grid = []
				@_resetProgress()
				@_forEachPolygon model, (p0, p1, p2, direction, progress) ->
					@_voxelizePolygon(
						p0
						p1
						p2
						direction
						lineStepSize
						grid
					)
					@_postProgress(progress, progressCallback)
				progressCallback state: 'finished', data: grid
				return

			_voxelizePolygon: (p0, p1, p2, dZ, lineStepSize, grid) ->
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

				longSideStepSize = 1 / (shortSideLength1 + shortSideLength2) * lineStepSize

				longSideIndex = 0

				for i in [0..1] by lineStepSize / shortSideLength1
					p0 = @_interpolateLine shortSide1, i
					p1 = @_interpolateLine longSide, longSideIndex
					longSideIndex += longSideStepSize
					@_voxelizeLine p0, p1, direction, lineStepSize, grid

				for i in [0..1] by lineStepSize / shortSideLength2
					p0 = @_interpolateLine shortSide2, i
					p1 = @_interpolateLine longSide, longSideIndex
					longSideIndex += longSideStepSize
					@_voxelizeLine p0, p1, direction, lineStepSize, grid

				return

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
				currentGridPosition = a

				for i in [0..length] by stepSize
					unless @_isOnVoxelBorder currentGridPosition
						oldVoxel = currentVoxel
						currentVoxel = @_roundVoxelSpaceToVoxel currentGridPosition
						if (oldVoxel.x != currentVoxel.x) or
						(oldVoxel.y != currentVoxel.y) or
						(oldVoxel.z != currentVoxel.z)
							z = @_getGreatestZInVoxel a, b, currentVoxel
							@_setVoxel currentVoxel, z, direction, grid
					currentGridPosition.x += dx
					currentGridPosition.y += dy
					currentGridPosition.z += dz
				return

			_isOnVoxelBorder: ({x, y, z}) ->
				for c in [x, y]
					return true if Math.abs(0.5 - (c % 1)) < @voxelRoundingThreshold
				return false

			_roundVoxelSpaceToVoxel: ({x: x, y: y, z: z}) ->
				return {
					x: Math.round x
					y: Math.round y
					z: Math.round z
				}

			_getGreatestZInVoxel: (a, b, {x: x, y: y, z: z}) ->
				roundA = @_roundVoxelSpaceToVoxel a
				roundB = @_roundVoxelSpaceToVoxel b

				aIsInVoxel = roundA.x is x and roundA.y is y and roundA.z is z
				bIsInVoxel = roundB.x is x and roundB.y is y and roundB.z is z

				if aIsInVoxel and bIsInVoxel
					return Math.max a.z, b.z
				if aIsInVoxel && a.z > b.z
					return a.z
				if bIsInVoxel && b.z > a.z
					return b.z

				d = x: b.x - a.x, y: b.y - a.y, z: b.z - a.z

				if d.z is 0
					# return the value that must be the greatest z in voxel --> a.z == b.z
					return a.z

				if d.x isnt 0
					k = (x - 0.5 - a.x) / d.x
					if 0 <= k <= 1
						return a.z + k * d.z

					k = (x + 0.5 - a.x) / d.x
					if 0 <= k <= 1
						return a.z + k * d.z

				if d.y isnt 0
					k = (y - 0.5 - a.y) / d.y
					if 0 <= k <= 1
						return a.z + k * d.z

					k = (y + 0.5 - a.y) / d.y
					if 0 <= k <= 1
						return a.z + k * d.z

				if d.z isnt 0
					minZ = z - 0.5
					k = (minZ - a.z) / d.z
					if 0 <= k <= 1
						return minZ

					maxZ = z + 0.5
					k = (maxZ - a.z) / d.z
					if 0 <= k <= 1
						return maxZ

			_setVoxel: ({x: x, y: y, z: z}, zValue, direction, grid) ->
				grid[x] = [] unless grid[x]
				grid[x][y] = [] unless grid[x][y]
				oldValue = grid[x][y][z]
				if oldValue
					# Update dir if new zValue is higher than the old one
					# by at least floatDelta to avoid setting direction to -1 if it is
					# within the tolerance of floatDelta
					if (direction isnt 0 and zValue > oldValue.z + @floatDelta) or
					# Prefer setting direction to 1 (i.e. close the voxel)
					(direction is 1 and zValue > oldValue.z - @floatDelta)
						oldValue.z = zValue
						oldValue.dir = direction
				else
					grid[x][y][z] = z: zValue, dir: direction

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
				return
		}

	_getTolerantDirection: (dZ, tolerance) ->
		return if dZ > tolerance then 1 else if dZ < -tolerance then -1 else 0

	setupGrid: (optimizedModel, options) ->
		@voxelGrid = new Grid(options.gridSpacing)
		@voxelGrid.setUpForModel optimizedModel, options
		return @voxelGrid
