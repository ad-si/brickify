THREE = require 'three'
GeometryCreator = require './visualization/GeometryCreator'

module.exports = class BrickVisualizer
	constructor: () ->
		@_createBrickMaterials()
		@currentlyWorking = false

	# expects a three node, an array of lego bricks (with positions in)
	# grid coordinates, and optionally a grid offset
	createVisibleBricks: (threeNode, brickData, grid) =>
		# do not create multiple layers of bricks at the same time
		# (happens when the user rapidly clicks with the mouse)
		###
		if @currentlyWorking
			return
		@currentlyWorking = true
		###
		
		@geometryCreator = new GeometryCreator(grid)
		threeNode.children = []

		for gridZ in [0..brickData.length - 1] by 1
			lastCallback = true if gridZ == (brickData.length - 1)
			###
			window.setTimeout @_layerCallback(
				grid, brickData[gridZ], threeNode, lastCallback),
					10 * gridZ
			###
			@_createLayer grid, brickData[gridZ], threeNode

	makeLayerVisible: (threeNode, layer) =>
		# makes all layers up to this layer visible
		for i in [0..threeNode.children.length - 1] by 1
			if i <= layer
				threeNode.children[i].visible = true
			else
				threeNode.children[i].visible = false

	_createLayer: (grid, brickLayer, threeNode) =>
		bricks = (@_createBrick grid, brick for brick in brickLayer)
		
		layerObject = new THREE.Object3D()
		layerObject.add brick for brick in bricks

		threeNode.add layerObject

	_layerCallback: (grid, brickLayer, threeNode, lastCallback = false) =>
		return () =>
			@_createLayer grid, brickLayer, threeNode
			if lastCallback
				@currentlyWorking = false

	_brickCallback: (grid, brick, threeNode) =>
		return () =>
			@_createBrick(grid, brick, threeNode)

	_createBrick: (grid, brick, threeNode) =>
		mat = @_getRandomMaterial()

		cube = @geometryCreator.getBrick brick.position,
			brick.size, mat
		brick.visualizationMaterial = mat
				
		return cube

	_getRandomMaterial: () =>
		i = Math.floor(Math.random() * @_brickMaterials.length)
		return @_brickMaterials[i]

	_createBrickMaterials: () =>
		@_brickMaterials = []
		@_brickMaterials.push @_createMaterial 0x530000
		@_brickMaterials.push @_createMaterial 0xfe2020
		@_brickMaterials.push @_createMaterial 0xba0000
		@_brickMaterials.push @_createMaterial 0xfe5c5c
		@_brickMaterials.push @_createMaterial 0xdb0000
		@_brickMaterials.push @_createMaterial 0x6b0000
		@_brickMaterials.push @_createMaterial 0xfe3939
		@_brickMaterials.push @_createMaterial 0xfe4d4d

	_createMaterial: (color) =>
		return new THREE.MeshLambertMaterial({
			color: color
			#opacity: 0.8
			#transparent: true
			})
