THREE = require 'three'

module.exports = class Grid
	constructor: (@spacing = {x: 8, y: 8, z: 3.2}) ->
		@origin = {x: 0, y: 0, z: 0}
		@numVoxelsX = 0
		@numVoxelsY = 0
		@numVoxelsZ = 0
		@zLayers = []

	setUpForModel: (optimizedModel, options) =>
		@modelTransform = options.modelTransform

		bb = optimizedModel.boundingBox()

		# if the object is moved in the scene (not in the origin),
		# think about that while building the grid
		if @modelTransform
			bbMinWorld = new THREE.Vector3()
			bbMinWorld.set bb.min.x, bb.min.y, bb.min.z
			bbMinWorld.applyProjection(@modelTransform)

			bbMaxWorld = new THREE.Vector3()
			bbMaxWorld.set bb.max.x, bb.max.y, bb.max.z
			bbMaxWorld.applyProjection(@modelTransform)
		else
			bbMinWorld = bb.min
			bbMaxWorld = bb.max

		# align the grid to the nearest visible lego brick on the viewed board
		# positive values: set minimum to lower grid match
		# (x: 85, lower grid match 80 --> subtract 5)
		# negative values: go to next grid match (-85, delta 5 --> -80)
		# and subtract spacing to get to next grid (-> e.g. -88)
		xDelta = (Math.floor(Math.abs(bbMinWorld.x)) % @spacing.x)
		if (bbMinWorld.x >= 0)
			ox = Math.floor(bbMinWorld.x) - xDelta
		else
			ox = ((-Math.floor(Math.abs(bbMinWorld.x))) + xDelta) - @spacing.x

		yDelta = (Math.floor(Math.abs(bbMinWorld.y)) % @spacing.y)
		if (bbMinWorld.y >= 0)
			oy = Math.floor(bbMinWorld.y) - yDelta
		else
			oy = ((-Math.floor(Math.abs(bbMinWorld.y))) + yDelta) - @spacing.y

		zDelta = (Math.floor(Math.abs(bbMinWorld.z)) % @spacing.z)
		if (bbMinWorld.z >= 0)
			oz = Math.floor(bbMinWorld.z) - zDelta
		else
			oz = ((-Math.floor(Math.abs(bbMinWorld.z))) + zDelta) - @spacing.z

		#subtract spacing/2 to match the lego knobs of the visible grid
		@origin = {
			x: ox - (@spacing.x / 2)
			y: oy - (@spacing.y / 2)
			z: oz + (@spacing.z / 2)
		}

		@numVoxelsX = Math.ceil (bbMaxWorld.x - bbMinWorld.x) / @spacing.x
		@numVoxelsX += 2

		@numVoxelsY = Math.ceil (bbMaxWorld.y - bbMinWorld.y) / @spacing.y
		@numVoxelsY += 2

		@numVoxelsZ = Math.ceil (bbMaxWorld.z - bbMinWorld.z) / @spacing.z
		@numVoxelsZ += 2

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

	setVoxel: (voxel, data = true) =>
		# sets the voxel with the given indices to true
		# the voxel may also contain data.
		if not @zLayers[voxel.z]
			@zLayers[voxel.z] = []
		if not @zLayers[voxel.z][voxel.x]
			@zLayers[voxel.z][voxel.x] = []

		if not @zLayers[voxel.z][voxel.x][voxel.y]?
			voxData = {dataEntrys: [data], enabled: true, brick: false}
			@zLayers[voxel.z][voxel.x][voxel.y] = voxData
		else
			#if the voxel already exists, push new data to existing array
			@zLayers[voxel.z][voxel.x][voxel.y].dataEntrys.push data

	forEachVoxel: (callback) =>
		for z in [0..@numVoxelsZ - 1] by 1
			for y in [0..@numVoxelsY - 1] by 1
				for x in [0..@numVoxelsX - 1] by 1
					if @zLayers[z]?[x]?[y]?
						vox = @zLayers[z][x][y]
						callback vox, x, y, z


