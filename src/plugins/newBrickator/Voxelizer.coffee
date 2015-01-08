THREE = require 'three'
Grid = require './Grid'

module.exports = class Voxelizer
	constructor: (@baseBrick) ->
		@voxelGrid = null

	createVisibleVoxels: (threeNode) =>
		geometry = new THREE.BoxGeometry(
			@voxelGrid.spacing.x, @voxelGrid.spacing.y, @voxelGrid.spacing.z )
		material = new THREE.MeshLambertMaterial({
			color: 0x00ffff
			ambient: 0x00ffff
		})

		for x in [0..@voxelGrid.numVoxelsX - 1] by 1
			for y in [0..@voxelGrid.numVoxelsY - 1] by 1
				for z in [0..@voxelGrid.numVoxelsZ - 1] by 1
					if @voxelGrid.zLayers[z]?[x]?[y]?
						if @voxelGrid.zLayers[z][x][y] == true
							cube = new THREE.Mesh( geometry, material )
							cube.translateX( @voxelGrid.origin.x + @voxelGrid.spacing.x * x)
							cube.translateY( @voxelGrid.origin.y + @voxelGrid.spacing.y * y)
							cube.translateZ( @voxelGrid.origin.z + @voxelGrid.spacing.z * z)
							threeNode.add(cube)

	voxelize: (optimizedModel) =>
		@setupGrid optimizedModel

		optimizedModel.forEachPolygon (p0, p1, p2) =>
			@voxelizePolygon p0, p1, p2

	voxelizePolygon: (p0, p1, p2) =>
		@voxelizeLine p0, p1
		@voxelizeLine p0, p2
		@voxelizeLine p1, p2

	voxelizeLine: (a, b) =>
		# http://de.wikipedia.org/wiki/Bresenham-Algorithmus
		# https://gist.github.com/yamamushi/5823518
		@visitAllPoints a.x, a.y, a.z, b.x, b.y, b.z, (x,y,z) =>
			@setGrid x, y, z

	visitAllPoints: (gx0, gy0, gz0, gx1, gy1, gz1, visitor) =>
		gx0idx = gx0 # Math.round(gx0)
		gy0idx = gy0 # Math.round(gy0)
		gz0idx = gz0 # Math.round(gz0)

		gx1idx = gx1 # Math.round(gx1)
		gy1idx = gy1 # Math.round(gy1)
		gz1idx = gz1 # Math.round(gz1)

		#stepping
		sx = if gx1idx > gx0idx then 1 else (if gx1idx < gx0idx then -1 else 0)
		sy = if gy1idx > gy0idx then 1 else (if gy1idx < gy0idx then -1 else 0)
		sz = if gz1idx > gz0idx then 1 else (if gz1idx < gz0idx then -1 else 0)
		sx = @voxelGrid.spacing.x * sx
		sy = @voxelGrid.spacing.y * sy
		sz = @voxelGrid.spacing.z * sz

		gx = gx0idx
		gy = gy0idx
		gz = gz0idx

		#Planes for each axis that we will next cross
		gxp = gx0idx + (if gx1idx > gx0idx then 1 else 0)
		gyp = gy0idx + (if gy1idx > gy0idx then 1 else 0)
		gzp = gz0idx + (if gz1idx > gz0idx then 1 else 0)

		#Only used for multiplying up the error margins
		vx = if gx1 == gx0 then 1 else (gx1 - gx0)
		vy = if gy1 == gy0 then 1 else (gy1 - gy0)
		vz = if gz1 == gz0 then 1 else (gz1 - gz0)

		#Error is normalized to vx * vy * vz so we only have to multiply up
		vxvy = vx * vy
		vxvz = vx * vz
		vyvz = vy * vz

		#Error from the next plane accumulators, scaled up by vx*vy*vz
		errx = (gxp - gx0) * vyvz
		erry = (gyp - gy0) * vxvz
		errz = (gzp - gz0) * vxvy

		derrx = sx * vyvz
		derry = sy * vxvz
		derrz = sz * vxvy

		testEscape = 1000

		while (true)
			visitor gx, gy, gz

			if (gx == gx1idx && gy == gy1idx && gz == gz1idx)
				break

			#Which plane do we cross first?
			xr = Math.abs(errx)
			yr = Math.abs(erry)
			zr = Math.abs(errz)

			if (sx != 0 && (sy == 0 || xr < yr) && (sz == 0 || xr < zr))
				gx += sx
				errx += derrx

			else if (sy != 0 && (sz == 0 || yr < zr))
				gy += sy
				erry += derry

			else if (sz != 0)
				gz += sz
				errz += derrz

			break if not (testEscape-- > 0)

	setGrid: (x, y, z)  ->
		x = Math.round((x - @voxelGrid.origin.x) / @voxelGrid.spacing.x)
		y = Math.round((y - @voxelGrid.origin.y) / @voxelGrid.spacing.y)
		z = Math.round((z - @voxelGrid.origin.z) / @voxelGrid.spacing.z)

		if not @voxelGrid.zLayers[z]
			@voxelGrid.zLayers[z] = []
		if not @voxelGrid.zLayers[z][x]
			@voxelGrid.zLayers[z][x] = []
		@voxelGrid.zLayers[z][x][y] = true

	setupGrid: (optimizedModel) ->
		@voxelGrid = new Grid(@baseBrick)
		@voxelGrid.setUpForModel optimizedModel
		return @voxelGrid
