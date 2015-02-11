THREE = require 'three'

module.exports = class BrickVisualizer
	constructor: () ->
		@_createBrickMaterials()
		@_createStabilityMaterials()
		@currentlyWorking = false

	# expects a three node, an array of lego bricks (with positions in)
	# grid coordinates, optionally a grid offset and whether or not to show
	# stability (default is off)
	createVisibleBricks: (threeNode, brickData, grid, showStability) =>
		# do not create multiple layers of bricks at the same time
		# (happens when the user rapidly clicks with the mouse)
		if @currentlyWorking
			return
		@currentlyWorking = true

		threeNode.children = []

		for gridZ in [0..brickData.length - 1] by 1
			lastCallback = true if gridZ == (brickData.length - 1)
			window.setTimeout @_layerCallback(
				grid, brickData[gridZ], threeNode, lastCallback, showStability),
					10 * gridZ

	_createLayer: (grid, brickLayer, threeNode, showStability) =>
		bricks = (@_createBrick grid, brick, showStability for brick in brickLayer)
		layerGeometry = new THREE.Geometry()
		for brick in bricks
			brick.updateMatrix()
			layerGeometry.merge brick.geometry, brick.matrix
		layerMesh = new THREE.Mesh(layerGeometry, @_getFaceMats(showStability))
		threeNode.add layerMesh

	_layerCallback: (grid, brickLayer, threeNode, lastCallback = false,
									 showStability) =>
		return () =>
			@_createLayer grid, brickLayer, threeNode, showStability
			if lastCallback
				@currentlyWorking = false

	_brickCallback: (grid, brick, threeNode) =>
		return () =>
			@_createBrick(grid, brick, threeNode)

	_createBrick: (grid, brick, showStability) =>
		cube = @_createBrickGeometry grid.spacing, brick, showStability

		#move the bricks to their position in the grid
		world = grid.mapVoxelToWorld brick.position
		cube.translateX( world.x )
		cube.translateY( world.y )
		cube.translateZ( world.z )
		cube

	_createBrickGeometry: (gridSpacing, brick, showStability) =>
		if showStability
			index = Math.round brick.getStability() * 19
		else
			index = @_getRandomMaterialIndex()
		brickSizeX = gridSpacing.x * brick.size.x
		brickSizeY = gridSpacing.y * brick.size.y
		brickSizeZ = gridSpacing.z * brick.size.z

		brickGeometry = new THREE.BoxGeometry(
			brickSizeX,
			brickSizeY,
			brickSizeZ
		)
		for face in brickGeometry.faces
			face.materialIndex = index

		cube = new THREE.Mesh(brickGeometry, @_getFaceMats(showStability))

		#add noppen
		noppe = new THREE.CylinderGeometry(
			#these numbers are made up to look good. don't use for csg operations
			gridSpacing.x * 0.3, gridSpacing.y * 0.3, gridSpacing.z * 0.7, 7
		)
		for face in noppe.faces
			face.materialIndex = index


		for xi in [0..brick.size.x - 1] by 1
			for yi in [0..brick.size.y - 1] by 1
				# only show knobs if there is no connected brick to it
				if brick.upperSlots[xi][yi] == false
					noppeMesh = new THREE.Mesh(noppe, @_getFaceMats(showStability))

					noppeMesh.translateX (gridSpacing.x * (xi + 0.5)) - (brickSizeX / 2)
					noppeMesh.translateY (gridSpacing.y * (yi + 0.5)) - (brickSizeY / 2)
					noppeMesh.translateZ (gridSpacing.z * 0.7)
					noppeMesh.rotation.x += 1.571

					noppeMesh.updateMatrix()
					brickGeometry.merge noppeMesh.geometry, noppeMesh.matrix

		cube = new THREE.Mesh(brickGeometry, @_getFaceMats(showStability))

		#translate so that the x:0 y:0 z:0 coordinate matches the models corner
		#(center of model is physical center of box)
		cube.translateX brickSizeX / 2.0
		cube.translateY brickSizeY / 2.0
		cube.translateX brickSizeZ / 2.0

		# normal voxels have their origin in the middle, so translate the brick
		# to match the center of a voxel
		cube.translateX gridSpacing.x / -2.0
		cube.translateY gridSpacing.y / -2.0
		cube.translateX gridSpacing.z / -2.0

		return cube

	_getRandomMaterialIndex: () =>
		return Math.floor(Math.random() * @_brickMaterials.length)

	_createBrickMaterials: () =>
		@_brickMaterials = []
		@_brickMaterials.push @_createMaterial 0xff9900
		@_brickMaterials.push @_createMaterial 0xcc7a00
		@_brickMaterials.push @_createMaterial 0xffad32
		@_brickMaterials.push @_createMaterial 0xe58900
		@_brickMaterials.push @_createMaterial 0xf77000
		@_brickMaterials.push @_createMaterial 0xff7d11
		@_brickMaterials.push @_createMaterial 0xff8b2b
		@_brickMaterials.push @_createMaterial 0xff9944
		@_brickMaterials.push @_createMaterial 0xffa75e
		@_brickMaterials.push @_createMaterial 0xffb577
		@_brickMaterials.push @_createMaterial 0xff9944

	_createStabilityMaterials: =>
		@_stabilityMaterials = []
		# 2 by 10 is the largest LEGO brick we support so an array of 21 suffices
		# to reflect all stability shades
		for i in [0..20] by 1
			red = Math.round(255 - i * 255 / 20) * 0x10000
			green = Math.round(i * 255 / 20) * 0x100
			blue = 0
			color = red + green + blue
			# opacity is between 0.75 (perfectly stable) and 1 (not stable at all)
			opacity = if i == 0 then 1 else 1 - i * 0.0125
			@_stabilityMaterials.push @_createMaterial(color, opacity)


	_createMaterial: (color, opacity = 1.0) =>
		material = new THREE.MeshLambertMaterial({
			color: color
			})
		material.opacity = opacity
		material.transparent = opacity < 1.0
		return material

	_getFaceMats: (showStability) =>
		materials = if showStability then @_stabilityMaterials else @_brickMaterials
		return new THREE.MeshFaceMaterial(materials)
