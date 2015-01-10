THREE = require 'three'

module.exports = class VoxelVisualizer
	constructor: (@threejsRootNode) ->
		return
		
	clear: () =>
		@threejsRootNode.children = []
		
	createVisibleVoxel: (grid) =>
		geometry = new THREE.BoxGeometry(
			grid.spacing.x, grid.spacing.y, grid.spacing.z )
		upMaterial = new THREE.MeshLambertMaterial({
			color: 0x46aeff #blue
			opacity: 0.5
			transparent: true
		})
		downMaterial = new THREE.MeshLambertMaterial({
			color: 0xff40a7 #pink
			opacity: 0.5
			transparent: true
		})
		neiterMaterial = new THREE.MeshLambertMaterial({
			color: 0xc8c8c8 #grey
			opacity: 0.5
			transparent: true
		})
		fillMaterial = new THREE.MeshLambertMaterial({
			color: 0x48b427 #green
			opacity: 0.5
			transparent: true
		})
	
		for x in [0..grid.numVoxelsX - 1] by 1
			for y in [0..grid.numVoxelsY - 1] by 1
				for z in [0..grid.numVoxelsZ - 1] by 1
					if grid.zLayers[z]?[x]?[y]?
						if grid.zLayers[z][x][y] != false
							voxel = grid.zLayers[z][x][y]
	
							if voxel.definitelyUp? and voxel.definitelyUp
								m = upMaterial
							else if voxel.definitelyDown? and voxel.definitelyDown
								m = downMaterial
							else if voxel.dataEntrys[0].inside? and
							voxel.dataEntrys[0].inside == true
								m = fillMaterial
							else
								m = neiterMaterial
	
							cube = new THREE.Mesh( geometry, m )
							cube.translateX( grid.origin.x + grid.spacing.x * x)
							cube.translateY( grid.origin.y + grid.spacing.y * y)
							cube.translateZ( grid.origin.z + grid.spacing.z * z)
	
							cube.voxelCoords  = {
								x: x
								y: y
								z: z
							}
	
							@threejsRootNode.add(cube)
