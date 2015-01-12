Grid = require './Grid'

module.exports = class Voxelizer
	constructor: (@baseBrick) ->
		@voxelGrid = null
		@voxelResolution = 1

	setDebugVoxel: (@debugVoxel) =>
		# allows for setting a breakpoint when voxelizing and inspecting
		# a specific voxel
		return

	voxelize: (optimizedModel, options = {}) =>
		if options.voxelResolution?
			@voxelResolution = options.voxelResolution

		@setupGrid optimizedModel

		optimizedModel.forEachPolygon (p0, p1, p2, n) =>
			@voxelizePolygon p0, p1, p2, n

		return @voxelGrid

	voxelizePolygon: (p0, p1, p2, n) =>
		# Align coordinates to grid origin so that we don't have ugly numbers
		p0 = @voxelGrid.mapWorldToGridRelative p0
		p1 = @voxelGrid.mapWorldToGridRelative p1
		p2 = @voxelGrid.mapWorldToGridRelative p2

		#store information for filling solids
		if n.z >= 0
			upwards = true
		else
			upwards = false

		voxelData = {
			up: upwards
		}

		#voxelize outer lines
		l0 = @voxelizeLine p0, p1, voxelData, true
		l0len = l0.length
		l1 = @voxelizeLine p1, p2, voxelData, true
		l1len = l1.length
		l2 = @voxelizeLine p2, p0, voxelData, true
		l2len = l2.length

		#sort for short and long side
		if l0len >= l1len and l0len >= l2len
			longSide  = l0
			shortSide1 = l1
			shortSide2 = l2
		else if l1len >= l0len and l1len >= l2len
			longSide = l1
			shortSide1 = l0.reverse()
			shortSide2 = l2.reverse()
		else # if l2len >= l0len and l2len >= l1len
			longSide = l2
			shortSide1 = l1.reverse()
			shortSide2 = l0.reverse()

		longSideIndex = 0
		longSideDelta =
			(longSide.length - 1) / (shortSide1.length + shortSide2.length)
		for i in [0..shortSide1.length - 1] by 1
			p0 = @voxelGrid.mapVoxelToGridRelative shortSide1[i]
			p1 = @voxelGrid.mapVoxelToGridRelative longSide[Math.round(longSideIndex)]
			longSideIndex += longSideDelta
			@voxelizeLine p0, p1, voxelData

		for i in [0..shortSide2.length - 1] by 1
			p0 = @voxelGrid.mapVoxelToGridRelative shortSide2[i]
			p1 = @voxelGrid.mapVoxelToGridRelative longSide[Math.round(longSideIndex)]
			longSideIndex += longSideDelta
			@voxelizeLine p0, p1, voxelData

	voxelizeLine: (a, b, voxelData = true, returnVoxel = false) =>
		# voxelizes the line from a to b
		# voxel data = something to store in the voxel grid for each voxel.
		# can be true for 'there is a voxel' or
		# a complex object with more information

		lineVoxels = []

		@visitAllPointsBresenham a, b, (p) =>
			@voxelGrid.setVoxel p, voxelData
			if returnVoxel
				lineVoxels.push p

		return lineVoxels

	visitAllPointsBresenham: (a, b, visitor) =>
		# http://de.wikipedia.org/wiki/Bresenham-Algorithmus
		# https://gist.github.com/yamamushi/5823518
		# a,b = math round a,b / math floor a,b

		stepDivision = @voxelResolution

		bvox = @voxelGrid.mapGridRelativeToVoxel b
		
		#stepping
		sx = if b.x > a.x then 1 else (if b.x < a.x then -1 else 0)
		sy = if b.y > a.y then 1 else (if b.y < a.y then -1 else 0)
		sz = if b.z > a.z then 1 else (if b.z < a.z then -1 else 0)
		sx = @voxelGrid.spacing.x * sx * (1 / stepDivision)
		sy = @voxelGrid.spacing.y * sy * (1 / stepDivision)
		sz = @voxelGrid.spacing.z * sz * (1 / stepDivision)

		g = {
			x: a.x
			y: a.y
			z: a.z
		}

		#Planes for each axis that we will next cross
		gxp = a.x + (if b.x > a.x then 1 else 0)
		gyp = a.y + (if b.y > a.y then 1 else 0)
		gzp = a.z + (if b.z > a.z then 1 else 0)

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

		securityBreak = 100000

		while (true)
			securityBreak--
			if securityBreak == 0
				break

			gvox_old = gvox
			gvox = @voxelGrid.mapGridRelativeToVoxel g

			if @debugVoxel
				if @debugVoxel.x == gvox.x and
			  @debugVoxel.y == gvox.y and
				@debugVoxel.z == gvox.z
					console.log 'Voxelizing debug voxel, put your breakpoint *here*'

			# if we move in this particular direction, check that we did not exeed our
			# destination bounds
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

	setupGrid: (optimizedModel) ->
		@voxelGrid = new Grid(@baseBrick)
		@voxelGrid.setUpForModel optimizedModel
		return @voxelGrid

