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
		# Align coordinates to grid origin so that we don't have ugly numbers
		p0 = @voxelGrid.mapWorldToGridRelative p0
		p1 = @voxelGrid.mapWorldToGridRelative p1
		p2 = @voxelGrid.mapWorldToGridRelative p2

		@voxelizeLine p0, p1
		@voxelizeLine p0, p2
		@voxelizeLine p1, p2

	voxelizeLine: (a, b) =>
		# http://de.wikipedia.org/wiki/Bresenham-Algorithmus
		# https://gist.github.com/yamamushi/5823518
		@visitAllPoints a, b, (p) =>
			@voxelGrid.setVoxel p

	visitAllPoints: (a, b, visitor) =>
		#a,b = math round a,b / math floor a,b

		bvox = @voxelGrid.mapGridRelativeToVoxel b
		
		#stepping
		sx = if b.x > a.x then 1 else (if b.x < a.x then -1 else 0)
		sy = if b.y > a.y then 1 else (if b.y < a.y then -1 else 0)
		sz = if b.z > a.z then 1 else (if b.z < a.z then -1 else 0)
		sx = @voxelGrid.spacing.x * sx
		sy = @voxelGrid.spacing.y * sy
		sz = @voxelGrid.spacing.z * sz

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

		testEscape = 1000

		while (true)
			gvox = @voxelGrid.mapGridRelativeToVoxel g

			if (sx > 0 && gvox.x > bvox.x) or (sx < 0 && gvox.x < bvox.x) and
			(sy > 0 && gvox.y > bvox.y) or (sy < 0 && gvox.y < bvox.y) and
			(sz > 0 && gvox.z > bvox.z) or (sz < 0 && gvox.z < bvox.z)
				break

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

			break if not (testEscape-- > 0)

	setupGrid: (optimizedModel) ->
		@voxelGrid = new Grid(@baseBrick)
		@voxelGrid.setUpForModel optimizedModel
		return @voxelGrid
