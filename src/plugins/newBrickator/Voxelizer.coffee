THREE = require 'three'
Grid = require './Grid'

module.exports = class Voxelizer
	constructor: (@baseBrick) ->
		@voxelGrid = null
		@voxelResolution = 1

	setDebugVoxel: (@debugVoxel) =>
		# allows for setting a breakpoint when voxelizing and inspecting
		# a specific voxel
		return

	createVisibleVoxels: (threeNode) =>
		geometry = new THREE.BoxGeometry(
			@voxelGrid.spacing.x, @voxelGrid.spacing.y, @voxelGrid.spacing.z )
		upMaterial = new THREE.MeshLambertMaterial({
			color: 0x46aeff #blue
			opacity: 0.5
			transparent: true
		})
		downMaterial = new THREE.MeshLambertMaterial({
			color: 0xff40a7 #pink
			opacity: 0.5
			transparent: true
		})
		neiterMaterial = new THREE.MeshLambertMaterial({
			color: 0xc8c8c8 #grey
			opacity: 0.5
			transparent: true
		})
		fillMaterial = new THREE.MeshLambertMaterial({
			color: 0x48b427 #green
			opacity: 0.5
			transparent: true
		})

		for x in [0..@voxelGrid.numVoxelsX - 1] by 1
			for y in [0..@voxelGrid.numVoxelsY - 1] by 1
				for z in [0..@voxelGrid.numVoxelsZ - 1] by 1
					if @voxelGrid.zLayers[z]?[x]?[y]?
						if @voxelGrid.zLayers[z][x][y] != false
							voxel = @voxelGrid.zLayers[z][x][y]

							if voxel.definitelyUp? and voxel.definitelyUp
								m = upMaterial
							else if voxel.definitelyDown? and voxel.definitelyDown
								m = downMaterial
							else if voxel.inside? and voxel.inside == true
								m = fillMaterial
							else
								m = neiterMaterial

							cube = new THREE.Mesh( geometry, m )
							cube.translateX( @voxelGrid.origin.x + @voxelGrid.spacing.x * x)
							cube.translateY( @voxelGrid.origin.y + @voxelGrid.spacing.y * y)
							cube.translateZ( @voxelGrid.origin.z + @voxelGrid.spacing.z * z)

							cube.voxelCoords  = {
								x: x
								y: y
								z: z
							}

							threeNode.add(cube)


	voxelize: (optimizedModel) =>
		start = new Date()
		console.log "Voxelizing model with Resoltuion #{@voxelResolution}"
		@setupGrid optimizedModel

		optimizedModel.forEachPolygon (p0, p1, p2, n) =>
			@voxelizePolygon p0, p1, p2, n

		fin = new Date() - start
		console.log "Finished voxelizing the shell in #{fin}ms. Filling volumes..."

		start = new Date()
		@fillGrid()
		fillEnd = new Date() - start
		console.log "Filled volumes in #{fillEnd}ms. Total time #{fin + fillEnd}ms"

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

		while (true)
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

	fillGrid: () ->
		# fills spaces in the grid. Goes up from z=0 to z=max and looks for
		# voxels facing downwards (start filling), stops when it sees voxels
		# facing upwards

		for x in [0..@voxelGrid.numVoxelsX - 1] by 1
			for y in [0..@voxelGrid.numVoxelsY - 1] by 1
				insideModel = false

				for z in [0..@voxelGrid.numVoxelsZ - 1] by 1
					if @voxelGrid.zLayers[z]?[x]?[y]?
						# current voxel already exists (shell voxel)
						dataEntrys = @voxelGrid.zLayers[z]?[x]?[y].dataEntrys
						numUp = 0
						numDown = 0
						for e in dataEntrys
							if e.up? and e.up == true
								numUp++
							else if e.up? and e.up == false
								numDown++

						if numUp > 0 and numDown == 0
							definitelyUp = true
						else
							definitelyUp = false

						if numDown > 0 and numUp == 0
							definitelyDown = true
						else
							definitelyDown = false

						@voxelGrid.zLayers[z][x][y].definitelyUp = definitelyUp
						@voxelGrid.zLayers[z][x][y].definitelyDown = definitelyDown

						if definitelyUp
							#leaving model
							insideModel = false
						else if definitelyDown
							insideModel = true
						else
							#if not sure, don't fill space
							insideModel = false
					else
						#voxel does not yet exist. create if inside model
						if insideModel
							@voxelGrid.setVoxel {x: x, y: y, z: z}, {inside: true}


	setupGrid: (optimizedModel) ->
		@voxelGrid = new Grid(@baseBrick)
		@voxelGrid.setUpForModel optimizedModel
		return @voxelGrid

