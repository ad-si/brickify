THREE = require 'three'
BrickObject = require './BrickObject'

# This class provides basic functionality to create simple Voxel/Brick geometry
module.exports = class GeometryCreator
	constructor: (@grid) ->
		@brickGeometryCache = {}
		@studGeometryCache = {}

		@stud = new THREE.CylinderGeometry(
			#these numbers are made up to look good. don't use for csg operations
			@grid.spacing.x * 0.3, @grid.spacing.y * 0.3, @grid.spacing.z * 0.7, 7
		)

		rotation = new THREE.Matrix4()
		rotation.makeRotationX(1.571)
		@stud.applyMatrix(rotation)

	getVoxel: (gridPosition, material) =>
		brick = @getBrick gridPosition, {x: 1, y: 1, z: 1}, material

		#store references (voxel) for further use
		brick.setVoxelCoords gridPosition
		brick.setGridReference @grid.getVoxel gridPosition

		return brick

	getBrick: (gridPosition, brickDimensions, material) =>
		# returns a THREE.Geometry that uses the given material and is
		# transformed to match the given grid position
		brickGeometry = @_getBrickGeometry(brickDimensions)
		studGeometry = @_getStudsGeometry(brickDimensions)

		brick = new BrickObject(brickGeometry, studGeometry, material)

		worldBrickSize = {
			x: brickDimensions.x * @grid.spacing.x
			y: brickDimensions.y * @grid.spacing.y
			z: brickDimensions.z * @grid.spacing.z
		}
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

	_getBrickGeometry: (brickDimensions) =>
		# returns a box geometry for the given dimensions

		ident = @_getHash brickDimensions
		if @brickGeometryCache[ident]?
			return @brickGeometryCache[ident]

		brickGeometry = new THREE.BoxGeometry(
			brickDimensions.x * @grid.spacing.x
			brickDimensions.y * @grid.spacing.y
			brickDimensions.z * @grid.spacing.z
		)

		@brickGeometryCache[ident] = brickGeometry
		return brickGeometry

	_getStudsGeometry: (brickDimensions) =>
		# returns studs for the given brick size

		ident = @_getHash brickDimensions
		if @studGeometryCache[ident]?
			return @studGeometryCache[ident]

		studs = new THREE.Geometry()

		worldBrickSize = {
			x: brickDimensions.x * @grid.spacing.x
			y: brickDimensions.y * @grid.spacing.y
			z: brickDimensions.z * @grid.spacing.z
		}

		for xi in [0..brickDimensions.x - 1] by 1
			for yi in [0..brickDimensions.y - 1] by 1
				tx = (@grid.spacing.x * (xi + 0.5)) - (worldBrickSize.x / 2)
				ty = (@grid.spacing.y * (yi + 0.5)) - (worldBrickSize.y / 2)
				tz = (@grid.spacing.z * 0.7)

				translation = new THREE.Matrix4()
				translation.makeTranslation(tx, ty, tz)

				studs.merge @stud, translation

		@studGeometryCache[ident] = studs
		return studs

	_getHash: (dimensions) ->
		return dimensions.x + '-' + dimensions.y + '-' + dimensions.z
