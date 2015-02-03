THREE = require 'three'

module.exports = class BrickVisualizer
	constructor: () ->
		@_createBrickMaterials()

	# expects a three node, an array of lego bricks (with positions in)
	# grid coordinates, and optionally a grid offset
	createVisibleBricks: (threeNode, brickData, grid) =>
		threeNode.children = []

		for gridZ in [0..brickData.length - 1] by 1
			for brick in brickData[gridZ]
				window.setTimeout @_brickCallback(
					grid, brick, threeNode),
					20 * gridZ
				
	_brickCallback: (grid, brick, threeNode) =>
		return () =>
			@_createBrick(grid, brick, threeNode)

	_createBrick: (grid, brick, threeNode) =>
		cube = @_createBrickGeometry grid.spacing, brick

		#move the bricks to their position in the grid
		world = grid.mapVoxelToWorld brick.position
		cube.translateX( world.x )
		cube.translateY( world.y )
		cube.translateZ( world.z )

		threeNode.add(cube)

	_createBrickGeometry: (gridSpacing, brick) =>
		brickSizeX = gridSpacing.x * brick.size.x
		brickSizeY = gridSpacing.y * brick.size.y
		brickSizeZ = gridSpacing.z * brick.size.z

		brickGeometry = new THREE.BoxGeometry(
			brickSizeX,
			brickSizeY,
			brickSizeZ
		)

		mat = @_getRandomMaterial()

		#add noppen
		noppe = new THREE.CylinderGeometry(
			#these numbers are made up to look good. don't use for csg operations
			gridSpacing.x * 0.3, gridSpacing.y * 0.3, gridSpacing.z * 0.7, 7
		)
		
		for xi in [0..brick.size.x - 1] by 1
			for yi in [0..brick.size.y - 1] by 1
				# only show knobs if there is no connected brick to it
				if brick.upperSlots[xi][yi] == false
					noppeMesh = new THREE.Mesh(noppe, mat)

					noppeMesh.translateX (gridSpacing.x * (xi + 0.5)) - (brickSizeX / 2)
					noppeMesh.translateY (gridSpacing.y * (yi + 0.5)) - (brickSizeY / 2)
					noppeMesh.translateZ (gridSpacing.z * 0.7)
					noppeMesh.rotation.x += 1.571

					noppeMesh.updateMatrix()
					brickGeometry.merge noppeMesh.geometry, noppeMesh.matrix

		cube = new THREE.Mesh(brickGeometry, mat)

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

	_getRandomMaterial: () =>
		i = Math.floor(Math.random() * @_brickMaterials.length)
		return @_brickMaterials[i]

	_createBrickMaterials: () =>
		@_brickMaterials = []
		@_brickMaterials.push @_createMaterial 0xff9900
		@_brickMaterials.push @_createMaterial 0xcc7a00
		@_brickMaterials.push @_createMaterial 0xffad32
		@_brickMaterials.push @_createMaterial 0xe58900

	_createMaterial: (color) =>
		return new THREE.MeshLambertMaterial({
			color: color
			#opacity: 0.8
			#transparent: true
			})

