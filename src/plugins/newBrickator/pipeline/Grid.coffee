THREE = require 'three'
Voxel = require './Voxel'
Brick = require './Brick'
Random = require './Random'

module.exports = class Grid
	constructor: (@spacing = {x: 8, y: 8, z: 3.2}) ->
		@origin = {x: 0, y: 0, z: 0}
		@numVoxelsX = 0
		@numVoxelsY = 0
		@numVoxelsZ = 0
		@heightRatio = ((@spacing.x + @spacing.y) / 2) / @spacing.z

		@voxels = {}

	setUpForModel: (model, options) =>
		@modelTransform = options.modelTransform

		model
			.getBoundingBox()
			.then (boundingBox) =>

				# if the object is moved in the scene (not in the origin),
				# think about that while building the grid
				if @modelTransform
					bbMinWorld = new THREE.Vector3()
					bbMinWorld.set(
						boundingBox.min.x
						boundingBox.min.y
						boundingBox.min.z
					)
					bbMinWorld.applyProjection(@modelTransform)

					bbMaxWorld = new THREE.Vector3()
					bbMaxWorld.set(
						boundingBox.max.x
						boundingBox.max.y
						boundingBox.max.z
					)
					bbMaxWorld.applyProjection(@modelTransform)
				else
					bbMinWorld = boundingBox.min
					bbMaxWorld = boundingBox.max

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

				maxVoxel = @mapWorldToGrid bbMaxWorld
				minVoxel = @mapWorldToGrid bbMinWorld

				@numVoxelsX = Math.ceil (maxVoxel.x - minVoxel.x) / @spacing.x + 2
				@numVoxelsY = Math.ceil (maxVoxel.y - minVoxel.y) / @spacing.y + 2
				@numVoxelsZ = Math.ceil (maxVoxel.z - minVoxel.z) / @spacing.z + 1

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
			if voxel.brick
				bricks.add voxel.brick

		return bricks

	# chooses a random brick
	chooseRandomBrick: =>
		while true
			x = Random.next(@numVoxelsX)
			y = Random.next(@numVoxelsY)
			z = Random.next(@numVoxelsZ)

			vox = @getVoxel x, y, z

			if vox? and vox.brick
				return vox.brick

