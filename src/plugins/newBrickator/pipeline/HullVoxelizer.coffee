log = require 'loglevel'
Grid = require './Grid'


module.exports = class Voxelizer
	constructor: ->
		@voxelGrid = null

	setDebugVoxel: (@debugVoxel) =>
		# allows for setting a breakpoint when voxelizing and inspecting
		# a specific voxel
		return

	voxelize: (optimizedModel, options = {}) =>
		if options.debugVoxel?
			@debugVoxel = options.debugVoxel

		@setupGrid optimizedModel, options

		optimizedModel.forEachPolygon (p0, p1, p2, n) =>
			@voxelizePolygon p0, p1, p2, n

		return {grid: @voxelGrid}

	voxelizePolygon: (p0, p1, p2, n) =>
		# transform model coordinates to grid coordinates
		# (object may be moved/rotated)
		p0 = @voxelGrid.mapModelToGrid p0
		p1 = @voxelGrid.mapModelToGrid p1
		p2 = @voxelGrid.mapModelToGrid p2

		#store information for filling solids
		voxelData = {
			dZ: n.z
		}

		#voxelize outer lines
		@voxelizeLine p0, p1, voxelData
		l0len = @_getLength p0, p1
		@voxelizeLine p1, p2, voxelData
		l1len = @_getLength p1, p2
		@voxelizeLine p2, p0, voxelData
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

		longSideIndex = 0
		longSideDelta = (longSideLength - 1) / (shortSideLength1 + shortSideLength2)

		for i in [0..shortSideLength1] by 1
			p0 = @_interpolateLine shortSide1, i / shortSideLength1
			p1 = @_interpolateLine longSide, longSideIndex / longSideLength
			longSideIndex += longSideDelta
			@voxelizeLine p0, p1, voxelData

		for i in [0..shortSideLength2] by 1
			p0 = @_interpolateLine shortSide2, i / shortSideLength2
			p1 = @_interpolateLine longSide, longSideIndex / longSideLength
			longSideIndex += longSideDelta
			@voxelizeLine p0, p1, voxelData

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

	voxelizeLine: (a, b, voxelData = true) =>
		# voxelizes the line from a to b
		# voxel data = something to store in the voxel grid for each voxel.
		# can be true for 'there is a voxel' or
		# a complex object with more information

		@visitAllPointsBresenham a, b, (p) =>
			@voxelGrid.setVoxel p, voxelData

	visitAllPointsBresenham: (a, b, visitor) =>
		# http://de.wikipedia.org/wiki/Bresenham-Algorithmus
		# https://gist.github.com/yamamushi/5823518
		# http://stackoverflow.com/questions/16505905/
		# walk-a-line-between-two-points-in-a-3d-voxel-space-visiting-all-cells

		afl = {
			x: Math.floor a.x
			y: Math.floor a.y
			z: Math.floor a.z
		}

		bfl = {
			x: Math.floor b.x
			y: Math.floor b.y
			z: Math.floor b.z
		}

		bvox = @voxelGrid.mapGridToVoxel bfl

		#stepping
		sx = if bfl.x > afl.x then 1 else (if bfl.x < afl.x then -1 else 0)
		sy = if bfl.y > afl.y then 1 else (if bfl.y < afl.y then -1 else 0)
		sz = if bfl.z > afl.z then 1 else (if bfl.z < afl.z then -1 else 0)

		g = {
			x: afl.x
			y: afl.y
			z: afl.z
		}

		#Planes for each axis that we will next cross
		gxp = afl.x + (if bfl.x > afl.x then 1 else 0)
		gyp = afl.y + (if bfl.y > afl.y then 1 else 0)
		gzp = afl.z + (if bfl.z > afl.z then 1 else 0)

		#Only used for multiplying up the error margins
		vx = if b.x == a.x then 1 else (b.x - a.x)
		vy = if b.y == a.y then 1 else (b.y - a.y)
		vz = if b.z == a.z then 1 else (b.z - a.z)

		#Error is normalized to vx * vy * vz so we only have to multiply up
		vxvy = vx * vy
		vxvz = vx * vz
		vyvz = vy * vz

		#Error from the next plane accumulators, scaled up by vx*vy*vz
		errx = (gxp - a.x) * vyvz
		erry = (gyp - a.y) * vxvz
		errz = (gzp - a.z) * vxvy

		derrx = sx * vyvz
		derry = sy * vxvz
		derrz = sz * vxvy

		gvox = {x: -2, y: -2, z: -2}
		gvox_old = {x: -1, y: -1, z: -1}

		while (true)
			gvox_old = gvox
			gvox = @voxelGrid.mapGridToVoxel g

			if @debugVoxel
				if @debugVoxel.x == gvox.x and
			  @debugVoxel.y == gvox.y and
				@debugVoxel.z == gvox.z
					log.debug 'Voxelizing debug voxel, put your breakpoint *here*'

			# if we move in this particular direction, check that we did not exeed our
			# destination bounds: check if we reached the destination voxel
			if ((sx == 0) or
			((sx > 0 && gvox.x >= bvox.x) or (sx < 0 && gvox.x <= bvox.x))) and
			((sy == 0) or
			((sy > 0 && gvox.y >= bvox.y) or (sy < 0 && gvox.y <= bvox.y))) and
			((sz == 0) or
			((sz > 0 && gvox.z >= bvox.z) or (sz < 0 && gvox.z <= bvox.z)))
				break

			if (gvox_old.x != gvox.x) or (gvox_old.y != gvox.y) or (gvox_old.z != gvox.z)
				visitor gvox

			#Which plane do we cross first?
			xr = Math.abs(errx)
			yr = Math.abs(erry)
			zr = Math.abs(errz)

			if (sx != 0 && (sy == 0 || xr < yr) && (sz == 0 || xr < zr))
				g.x += sx
				errx += derrx

			else if (sy != 0 && (sz == 0 || yr < zr))
				g.y += sy
				erry += derry

			else if (sz != 0)
				g.z += sz
				errz += derrz

	setupGrid: (optimizedModel, options) ->
		@voxelGrid = new Grid(options.gridSpacing)
		@voxelGrid.setUpForModel optimizedModel, options
		return @voxelGrid

