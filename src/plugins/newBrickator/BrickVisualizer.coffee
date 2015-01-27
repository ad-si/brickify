THREE = require 'three'

module.exports = class BrickVisualizer
	constructor: () ->
		@brickMaterial = new THREE.MeshLambertMaterial({
			color: 0xAAAA00
			opacity: 0.8
			transparent: true
		})

	# expects a three node, an array of lego bricks (with positions in)
	# grid coordinates, and optionally a grid offset
	createVisibleBricks: (threeNode, brickData, grid) =>
		@gridSpacing = grid.spacing
		@gridOrigin = grid.origin

		for gridZ in [0..brickData.length - 1] by 1
			for brick in brickData[gridZ]
				brickSizeX = @gridSpacing.x * brick.size.x
				brickSizeY = @gridSpacing.y * brick.size.y
				# currently, the layouter only supports platees with h=1
				brickSizeZ = @gridSpacing.z * 1.0

				@brickGeometry = new THREE.BoxGeometry(
					brickSizeX,
					brickSizeY,
					brickSizeZ
				)

				cube = new THREE.Mesh( @brickGeometry, @brickMaterial )

				#translate so that the x:0 y:0 z:0 coordinate matches the models corner
				#(center of model is physical center of box)
				cube.translateX brickSizeX / 2.0
				cube.translateY brickSizeY / 2.0
				cube.translateX brickSizeZ / 2.0

				# normal voxels have their origin in the middle, so translate the brick
				# to match the center of a voxel
				cube.translateX @gridSpacing.x / -2.0
				cube.translateY @gridSpacing.y / -2.0
				cube.translateX @gridSpacing.z / -2.0
				
				#move the bricks to their position in the grid
				cube.translateX( @gridOrigin.x + @gridSpacing.x * brick.position.x)
				cube.translateY( @gridOrigin.y + @gridSpacing.y * brick.position.y)
				cube.translateZ( @gridOrigin.z + @gridSpacing.z * gridZ)

				threeNode.add(cube)
