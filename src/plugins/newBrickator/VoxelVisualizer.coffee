THREE = require 'three'

module.exports = class VoxelVisualizer
	constructor: () ->
		@selectedMaterial = new THREE.MeshLambertMaterial({
			color: 0xffa500 #orange
			opacity: 0.2
			transparent: true
		})
		@deselectedMaterial = new THREE.MeshLambertMaterial({
			color: 0xc8c8c8 #gray
			opacity: 0.5
			transparent: true
		})
		
	clear: (threeNode) ->
		if threeNode?
			threeNode.children = []
		
	createVisibleVoxels: (grid, threeNode, drawInnerVoxels = true) =>
		@clear(threeNode)

		@voxelGeometry = new THREE.BoxGeometry(
			grid.spacing.x, grid.spacing.y, grid.spacing.z )

		for z in [0..grid.numVoxelsZ - 1] by 1
				window.setTimeout @zLayerCallback(grid, threeNode, drawInnerVoxels, z),
					10 * z

	zLayerCallback: (grid, threeNode, drawInnerVoxels, z) =>
		return () =>
			@createZLayer grid, threeNode, drawInnerVoxels, z

	createZLayer: (grid, threeNode, drawInnerVoxels, z) =>
		for x in [0..grid.numVoxelsX - 1] by 1
			for y in [0..grid.numVoxelsY - 1] by 1
				if grid.zLayers[z]?[x]?[y]?
					if grid.zLayers[z][x][y] != false
						if not drawInnerVoxels
							if grid.zLayers[z][x][y].dataEntrys[0].inside == true
								continue

						@createVoxel grid, threeNode, x, y, z

	createVoxel: (grid, threeNode, x, y, z) =>
		voxel = grid.zLayers[z][x][y]

		if voxel.enabled
			m = @selectedMaterial
		else
			m = @deselectedMaterial

		cube = new THREE.Mesh( @voxelGeometry, m )
		cube.translateX( grid.origin.x + grid.spacing.x * x)
		cube.translateY( grid.origin.y + grid.spacing.y * y)
		cube.translateZ( grid.origin.z + grid.spacing.z * z)

		cube.voxelCoords  = {
			x: x
			y: y
			z: z
		}

		threeNode.add(cube)
