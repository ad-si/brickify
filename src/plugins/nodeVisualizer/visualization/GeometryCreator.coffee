THREE = require 'three'
BrickObject = require './BrickObject'

# This class provides basic functionality to create simple Voxel/Brick geometry
module.exports = class GeometryCreator
	constructor: (@globalConfig, @grid) ->
		@brickGeometryCache = {}
		@studGeometryCache = {}
		@highFiStudGeometryCache = {}
		@planeGeometryCache = {}

		studRotation = new THREE.Matrix4()
		studRotation.makeRotationX(1.571)

		studTranslation = new THREE.Matrix4()
		studTranslation.makeTranslation 0, 0, @globalConfig.studSize.height / 2

		@studGeometry = new THREE.CylinderGeometry(
			@globalConfig.studSize.radius
			@globalConfig.studSize.radius
			@globalConfig.studSize.height
			7
		)
		@studGeometry.applyMatrix studRotation
		@studGeometry.applyMatrix studTranslation

		@highFiStudGeometry = new THREE.CylinderGeometry(
			@globalConfig.studSize.radius
			@globalConfig.studSize.radius
			@globalConfig.studSize.height
			42
		)

		@highFiStudGeometry.applyMatrix studRotation
		@highFiStudGeometry.applyMatrix studTranslation

	getBrick: (gridPosition, brickDimensions, materials, fidelity) =>
		# returns a THREE.Geometry that uses the given material and is
		# transformed to match the given grid position
		worldBrickSize = {
			x: brickDimensions.x * @grid.spacing.x
			y: brickDimensions.y * @grid.spacing.y
			z: brickDimensions.z * @grid.spacing.z
		}

		geometries = {
			brickGeometry: @_getBrickGeometry brickDimensions, worldBrickSize
			studGeometry: @_getStudsGeometry(
				brickDimensions
				worldBrickSize
				@studGeometryCache
				@studGeometry
			)
			highFiStudGeometry: @_getStudsGeometry(
				brickDimensions
				worldBrickSize
				@highFiStudGeometryCache
				@highFiStudGeometry
			)
			planeGeometry: @_getPlaneGeometry brickDimensions, worldBrickSize
		}

		brick = new BrickObject(
			geometries
			materials
			fidelity
		)

		worldBrickPosition = @grid.mapVoxelToWorld gridPosition

		#translate so that the x:0 y:0 z:0 coordinate matches the models corner
		#(center of model is physical center of box)
		brick.translateX worldBrickSize.x / 2.0
		brick.translateY worldBrickSize.y / 2.0
		brick.translateZ worldBrickSize.z / 2.0

		# normal voxels have their origin in the middle, so translate the brick
		# to match the center of a voxel
		brick.translateX @grid.spacing.x / -2.0
		brick.translateY @grid.spacing.y / -2.0
		brick.translateZ @grid.spacing.z / -2.0

		# move to world position
		brick.translateX worldBrickPosition.x
		brick.translateY worldBrickPosition.y
		brick.translateZ worldBrickPosition.z

		return brick

	getBrickBox: (boxDimensions, material) =>
		geometry = @_getBrickGeometry boxDimensions
		box = new THREE.Mesh geometry, material
		box.dimensions = boxDimensions
		return box

	_getBrickGeometry: (brickDimensions, worldBrickSize) =>
		# returns a box geometry for the given dimensions

		worldBrickSize ?= {
			x: brickDimensions.x * @grid.spacing.x
			y: brickDimensions.y * @grid.spacing.y
			z: brickDimensions.z * @grid.spacing.z
		}

		dimensionsHash = @_getHash brickDimensions
		if @brickGeometryCache[dimensionsHash]?
			return @brickGeometryCache[dimensionsHash]

		brickGeometry = new THREE.BoxGeometry(
			worldBrickSize.x
			worldBrickSize.y
			worldBrickSize.z
		)

		@brickGeometryCache[dimensionsHash] = brickGeometry
		return brickGeometry

	_getStudsGeometry: (brickDimensions, worldBrickSize, cache, geometry) =>
		# returns studs for the given brick size

		dimensionsHash = @_getHash brickDimensions
		if cache[dimensionsHash]?
			return cache[dimensionsHash]

		studs = new THREE.Geometry()

		for xi in [0..brickDimensions.x - 1] by 1
			for yi in [0..brickDimensions.y - 1] by 1
				tx = (@grid.spacing.x * (xi + 0.5)) - (worldBrickSize.x / 2)
				ty = (@grid.spacing.y * (yi + 0.5)) - (worldBrickSize.y / 2)
				tz = (@grid.spacing.z * brickDimensions.z) - (worldBrickSize.z / 2)

				translation = new THREE.Matrix4()
				translation.makeTranslation(tx, ty, tz)

				studs.merge geometry, translation

		bufferGeometry = new THREE.BufferGeometry()
		bufferGeometry.fromGeometry studs

		cache[dimensionsHash] = bufferGeometry
		return bufferGeometry

	_getPlaneGeometry: (brickDimensions, worldBrickSize) =>
		# returns studs for the given brick size

		dimensionsHash = @_getHash brickDimensions
		if @planeGeometryCache[dimensionsHash]?
			return @planeGeometryCache[dimensionsHash]

		studs = new THREE.PlaneBufferGeometry(
			@grid.spacing.x * brickDimensions.x
			@grid.spacing.y * brickDimensions.y
		)

		tz = (@grid.spacing.z * brickDimensions.z) - (worldBrickSize.z / 2)
		translation = new THREE.Matrix4()
		translation.makeTranslation(0, 0, tz)
		studs.applyMatrix translation

		@planeGeometryCache[dimensionsHash] = studs
		return studs

	_getHash: (dimensions) ->
		return dimensions.x + '-' + dimensions.y + '-' + dimensions.z
