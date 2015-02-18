THREE = require 'three'
GeometryCreator = require './visualization/GeometryCreator'

module.exports = class VoxelVisualizer
	constructor: () ->
		@selectedMaterial = new THREE.MeshLambertMaterial({
			color: 0xff0000 #orange
			opacity: 0.2
			#transparent: true
		})
		@deselectedMaterial = new THREE.MeshLambertMaterial({
			color: 0xb5ffb8 #greenish gray
			opacity: 0.8
			transparent: true
		})
		@hiddenMaterial = new THREE.MeshLambertMaterial({
			color: 0xffaaaa #gray
			opacity: 0.0
			transparent: true
		})
		
	clear: (threeNode) ->
		if threeNode?
			threeNode.children = []
		
	createVisibleVoxels: (grid, threeNode, drawInnerVoxels = true) =>
		@geometryCreator = new GeometryCreator(grid)
		@clear(threeNode)

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
			if voxel.brick and voxel.brick.visualizationMaterial?
				m = voxel.brick.visualizationMaterial
			else
				m = @selectedMaterial
		else
			m = @hiddenMaterial

		threeVoxel = @geometryCreator.getVoxel {x: x, y: y, z: z}, m
		threeNode.add(threeVoxel)

	updateVoxels: (grid, threeNode) =>
		if threeNode.children?
			for child in threeNode.children
				c = child.voxelCoords
				vox = grid.zLayers[c.z][c.x][c.y]

				if vox.enabled and vox.brick and vox.brick.visualizationMaterial?
					child.material = vox.brick.visualizationMaterial
				else
					child.material = @hiddenMaterial
