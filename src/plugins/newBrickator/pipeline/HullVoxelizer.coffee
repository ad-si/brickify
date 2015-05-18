log = require 'loglevel'
Grid = require './Grid'


module.exports = class Voxelizer
	constructor: ->
		@voxelGrid = null


	voxelize: (optimizedModel, options) =>
		@setupGrid optimizedModel, options

		optimizedModel.forEachPolygon (p0, p1, p2, n) =>
			@voxelizePolygon p0, p1, p2, n

		return {grid: @voxelGrid}

	voxelizePolygon: (p0, p1, p2, n) =>
		# transform model coordinates to grid coordinates
		# (object may be moved/rotated)
		p0 = @voxelGrid.mapModelToVoxelSpace p0
		p1 = @voxelGrid.mapModelToVoxelSpace p1
		p2 = @voxelGrid.mapModelToVoxelSpace p2

		#store information for filling solids
		voxelData = {
			dZ: n.z
		}

		lineStepSize = @voxelGrid.heightRatio / 16

		l0len = @_getLength p0, p1
		l1len = @_getLength p1, p2
		l2len = @_getLength p2, p0

		#sort for short and long side
		if l0len >= l1len and l0len >= l2len
			longSide  = {start: p0, end: p1}
			shortSide1 = {start: p1, end: p2}
			shortSide2 = {start: p2, end: p0}

			longSideLength = l0len
			shortSideLength1 = l1len
			shortSideLength2 = l2len
		else if l1len >= l0len and l1len >= l2len
			longSide = {start: p1, end: p2}
			shortSide1 = {start: p1, end: p0}
			shortSide2 = {start: p0, end: p2}

			longSideLength = l1len
			shortSideLength1 = l0len
			shortSideLength2 = l2len
		else # if l2len >= l0len and l2len >= l1len
			longSide = {start: p2, end: p0}
			shortSide1 = {start: p2, end: p1}
			shortSide2 = {start: p1, end: p0}

			longSideLength = l2len
			shortSideLength1 = l1len
			shortSideLength2 = l0len

		stepSize = @voxelGrid.heightRatio / 5
		longSideDelta = longSideLength / (shortSideLength1 + shortSideLength2 + 2)
		longSideDelta *= stepSize

		longSideIndex = longSideDelta

		for i in [0..shortSideLength1] by stepSize
			p0 = @_interpolateLine shortSide1, i / shortSideLength1
			p1 = @_interpolateLine longSide, longSideIndex / longSideLength
			longSideIndex += longSideDelta
			@voxelizeLine p0, p1, voxelData, lineStepSize

		for i in [0..shortSideLength2] by stepSize
			p0 = @_interpolateLine shortSide2, i / shortSideLength2
			p1 = @_interpolateLine longSide, longSideIndex / longSideLength
			longSideIndex += longSideDelta
			@voxelizeLine p0, p1, voxelData, lineStepSize

	_getLength: ({x: x1, y: y1, z: z1}, {x: x2, y: y2, z: z2}) ->
		x = (x1 - x2) * (x1 - x2)
		y = (y1 - y2) * (y1 - y2)
		z = (z1 - z2) * (z1 - z2)
		return Math.sqrt x + y + z

	_interpolateLine: ({start: {x: x1, y: y1, z: z1},
	end: {x: x2, y: y2, z: z2}}, i) ->
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
	voxelizeLine: (a, b, voxelData, stepSize) =>
		length = @_getLength a, b
		dx = (b.x - a.x) / length * stepSize
		dy = (b.y - a.y) / length * stepSize
		dz = (b.z - a.z) / length * stepSize

		currentVoxel = x: 0, y: 0, z: -1 # not a valid voxel because of z < 0
		currentGridPosition = x: a.x, y: a.y, z: a.z

		for i in [0..length] by stepSize
			oldVoxel = currentVoxel
			currentVoxel = @voxelGrid.mapVoxelSpaceToVoxel currentGridPosition
			if (oldVoxel.x != currentVoxel.x) or
			(oldVoxel.y != currentVoxel.y) or
			(oldVoxel.z != currentVoxel.z)
				@voxelGrid.setVoxel currentVoxel, voxelData
			currentGridPosition.x += dx
			currentGridPosition.y += dy
			currentGridPosition.z += dz

	setupGrid: (optimizedModel, options) ->
		@voxelGrid = new Grid(options.gridSpacing)
		@voxelGrid.setUpForModel optimizedModel, options
		return @voxelGrid
