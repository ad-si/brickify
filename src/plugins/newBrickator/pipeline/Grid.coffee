THREE = require 'three'
Voxel = require './Voxel'
Brick = require './Brick'
Random = require './Random'

module.exports = class Grid
	constructor: (@spacing = {x: 8, y: 8, z: 3.2}) ->
		@origin = {x: 0, y: 0, z: 0}
		@heightRatio = ((@spacing.x + @spacing.y) / 2) / @spacing.z

		@voxels = {}

	setUpForModel: (optimizedModel, options) =>
		@modelTransform = options.modelTransform

		bb = optimizedModel.boundingBox()

		# if the object is moved in the scene (not in the origin),
		# think about that while building the grid
		if @modelTransform
			bbMinWorld = new THREE.Vector3()
			bbMinWorld.set bb.min.x, bb.min.y, bb.min.z
			bbMinWorld.applyProjection(@modelTransform)
		else
			bbMinWorld = bb.min

		# 1.) Align bb minimum to next voxel position
		# 2.) spacing / 2 is subtracted to make the grid be aligned to the
		# voxel center
		# 3.) minimum z is to assure that grid is never below z=0
		calculatedZ = Math.floor(bbMinWorld.z / @spacing.z) * @spacing.z
		calculatedZ -= @spacing.z / 2
		minimumZ = @spacing.z / 2

		@origin = {
			x: Math.floor(bbMinWorld.x / @spacing.x) * @spacing.x - (@spacing.x / 2)
			y: Math.floor(bbMinWorld.y / @spacing.y) * @spacing.y - (@spacing.y / 2)
			z: Math.max(calculatedZ, minimumZ)
		}

	getNumVoxelsX: =>
		return @_maxVoxelX - @_minVoxelX + 1

	getNumVoxelsY: =>
		return @_maxVoxelY - @_minVoxelY + 1

	getNumVoxelsZ: =>
		return @_maxVoxelZ - @_minVoxelZ + 1

	# use this if you are not interested in the actual number of layers
	# e.g. if you want to use them zero-indexed
	getMaxZ: =>
		return @_maxVoxelZ

	_updateMinMax: ({x: x, y: y, z: z}) =>
		@_maxVoxelX ?= 0
		@_maxVoxelY ?= 0
		@_maxVoxelZ ?= 0

		@_maxVoxelX = Math.max @_maxVoxelX, x
		@_maxVoxelY = Math.max @_maxVoxelY, y
		@_maxVoxelZ = Math.max @_maxVoxelZ, z

		@_minVoxelX ?= @_maxVoxelX
		@_minVoxelY ?= @_maxVoxelY
		@_minVoxelZ ?= @_maxVoxelZ

		@_minVoxelX = Math.min @_minVoxelX, x
		@_minVoxelY = Math.min @_minVoxelY, y
		@_minVoxelZ = Math.min @_minVoxelZ, z

	mapWorldToGrid: (point) =>
		# maps world coordinates to aligned grid coordinates
		# aligned grid coordinates are world units, but relative to the
		# grid origin

		return {
			x: point.x - @origin.x
			y: point.y - @origin.y
			z: point.z - @origin.z
		}

	mapModelToGrid: (point) =>
		# maps the model local coordinates to the grid coordinates by first
		# transforming it with the modelTransform to world coordinates
		# and then converting it to aligned grid coordinates

		if @modelTransform?
			v = new THREE.Vector3(point.x, point.y, point.z)
			v.applyProjection(@modelTransform)
			return @mapWorldToGrid v
		else
			# if model is placed at 0|0|0,
			# model and world coordinates are in the same system
			return @mapWorldToGrid point

	mapGridToVoxel: (point) =>
		# maps aligned grid coordinates to voxel indices
		# cut z<0 to z=0, since the grid cannot have
		# voxels in negative direction
		return {
			x: Math.round(point.x / @spacing.x)
			y: Math.round(point.y / @spacing.y)
			z: Math.max(Math.round(point.z / @spacing.z), 0)
		}

	mapVoxelToGrid: (point) =>
		# maps voxel indices to aligned grid coordinates
		return {
			x: point.x * @spacing.x
			y: point.y * @spacing.y
			z: point.z * @spacing.z
		}

	mapVoxelToWorld: (point) =>
		# maps voxel indices to world coordinates
		relative = @mapVoxelToGrid point
		return {
			x: relative.x + @origin.x
			y: relative.y + @origin.y
			z: relative.z + @origin.z
		}

	# generates a key for a hashmap from the given coordinates
	_generateKey: (x, y, z) ->
		return x + '-' + y + '-' + z

	setVoxel: (position, data = true) ->
		key = @_generateKey position.x, position.y, position.z
		v = @voxels[key]

		if not v?
			v = new Voxel(position, [data])
			@_linkNeighbors v
			@voxels[key] = v
			@_updateMinMax position
		else
			v.dataEntrys.push data

		return v

	# links neighbours of this voxel with this voxel
	_linkNeighbors: (voxel) ->
		p = voxel.position

		zp = @getVoxel p.x, p.y, p.z + 1
		zm = @getVoxel p.x, p.y, p.z - 1
		xp = @getVoxel p.x + 1, p.y, p.z
		xm = @getVoxel p.x - 1, p.y, p.z
		yp = @getVoxel p.x, p.y + 1, p.z
		ym = @getVoxel p.x, p.y - 1, p.z

		if zp?
			voxel.neighbors.Zp = zp
			zp.neighbors.Zm = voxel

		if zm?
			voxel.neighbors.Zm = zm
			zm.neighbors.Zp = voxel

		if xp?
			voxel.neighbors.Xp = xp
			xp.neighbors.Xm = voxel

		if xm?
			voxel.neighbors.Xm = xm
			xm.neighbors.Xp = voxel

		if yp?
			voxel.neighbors.Yp = yp
			yp.neighbors.Ym = voxel

		if ym?
			voxel.neighbors.Ym = ym
			ym.neighbors.Yp = voxel

	getVoxel: (x, y, z) =>
		return @voxels[@_generateKey x, y, z]

	hasVoxelAt: (x, y, z) =>
		return @voxels[@_generateKey x, y, z]?

	forEachVoxel: (callback) =>
		for own key of @voxels
			callback @voxels[key]

	getDisabledVoxels: =>
		voxels = []
		@forEachVoxel (voxel) -> voxels.push voxel unless voxel.enabled
		return voxels

	getNeighbors: (x, y, z, selectionCallback) =>
		# returns a list of neighbors for this voxel position.
		# the selectionCallback(neighbor) defines what to return
		# and has to return true, if the voxel neighbor should be collected
		list = []

		pos = [
			[x + 1, y, z]
			[x - 1, y, z]
			[x, y + 1, z]
			[x, y - 1, z]
			[x, y, z + 1]
			[x, y, z - 1]
		]

		for p in pos
			v = @voxel[@_generateKey p[0], p[1], p[2]]
			if v? and selectionCallback(v)
				list.push v

		return list

	getSurrounding: ({x, y, z}, size, selectionCallback) =>
		list = []

		_collect = (vx, vy, vz) =>
			voxel = @voxels[@_generateKey vx, vy, vz]
			if voxel?
				list.push voxel if selectionCallback voxel

		sizeX_2 = Math.floor size.x / 2
		sizeY_2 = Math.floor size.y / 2
		sizeZ_2 = Math.floor size.z / 2
		for vx in [x - sizeX_2 .. x + sizeX_2] by 1
			for vy in [y - sizeY_2 .. y + sizeY_2] by 1
				for vz in [z - sizeZ_2 .. z + sizeZ_2] by 1
					_collect vx, vy, vz

		return list

	# Initializes the grid with a 1x1x1 brick for each voxel
	# Overrides existing bricks
	initializeBricks: =>
		@forEachVoxel (voxel) ->
			new Brick([voxel])

	# returns all bricks as a set
	getAllBricks: =>
		bricks = new Set()

		@forEachVoxel (voxel) ->
			if voxel.enabled and voxel.brick
				bricks.add voxel.brick

		return bricks

	# chooses a random brick
	chooseRandomBrick: =>
		while true
			x = @_minVoxelX + Random.next @getNumVoxelsX()
			y = @_minVoxelY + Random.next @getNumVoxelsY()
			z = @_minVoxelZ + Random.next @getNumVoxelsZ()

			vox = @getVoxel x, y, z

			if vox? and vox.brick
				return vox.brick

	intersectVoxels: (rayOrigin, rayDirection) =>
		dirfrac = {
			x: 1.0 / rayDirection.x
			y: 1.0 / rayDirection.y
			z: 1.0 / rayDirection.z
		}

		intersections = []

		@forEachVoxel (voxel) =>
			distance = @_intersectVoxel voxel, dirfrac, rayOrigin
			if (distance > 0)
				intersections.push {
					distance: distance
					voxel: voxel
				}

		intersections.sort (a,b) -> return a.distance - b.distance
		return intersections

	# Intersects a ray (1/direction + origin) with a voxel. returns the distance
	# until intersection, a value <0 means no intersection
	_intersectVoxel: (voxel, dirfrac, rayOrigin) =>
		# source:
		# http://gamedev.stackexchange.com/questions/18436/

		worldPosition = @mapVoxelToWorld voxel.position
		lower = {
			x: worldPosition.x - (@spacing.x / 2.0)
			y: worldPosition.y - (@spacing.y / 2.0)
			z: worldPosition.z - (@spacing.z / 2.0)
		}
		upper = {
			x: worldPosition.x + (@spacing.x / 2.0)
			y: worldPosition.y + (@spacing.y / 2.0)
			z: worldPosition.z + (@spacing.z / 2.0)
		}

		t1 = (lower.x - rayOrigin.x) * dirfrac.x
		t2 = (upper.x - rayOrigin.x) * dirfrac.x
		t3 = (lower.y - rayOrigin.y) * dirfrac.y
		t4 = (upper.y - rayOrigin.y) * dirfrac.y
		t5 = (lower.z - rayOrigin.z) * dirfrac.z
		t6 = (upper.z - rayOrigin.z) * dirfrac.z

		tmin = Math.max(
			Math.max(Math.min(t1, t2), Math.min(t3, t4)), Math.min(t5, t6)
		)
		tmax = Math.min(
			Math.min(Math.max(t1, t2), Math.max(t3, t4)), Math.max(t5, t6)
		)

		if (tmax < 0 || tmin > tmax)
			return -1
		else
			return tmin




