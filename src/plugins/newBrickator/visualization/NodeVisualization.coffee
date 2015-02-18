GeometryCreator = require './GeometryCreator'
THREE = require 'three'
Coloring = require './Coloring'

# This class represents the visualization of a node in the scene
module.exports = class NodeVisualization
	constructor: (@threeNode, @grid) =>
		@voxelsSubnode = new THREE.Object3D()
		@bricksSubnode = new THREE.Object3D()

		@threeNode.add @voxelsSubnode
		@threeNode.add @bricksSubnode

		@defaultColoring = new Coloring()
		@geometryCreator = new GeometryCreator()

	showVoxels: () =>
		@voxelsSubnode.visibility = true
		@bricksSubnode.visibility = false

	showBricks: () =>
		@bricksSubnode.visibility = true
		@voxelsSubnode.visibility = false

	updateVoxelVisualization: (coloring = @defaultColoring) =>
		if @voxelsSubnode.children?
			@voxelsSubnode.children = []

		for z in [0..@grid.numVoxelsZ - 1] by 1
			for x in [0..@grid.numVoxelsX - 1] by 1
				for y in [0..@grid.numVoxelsY - 1] by 1
					if grid.zLayers[z]?[x]?[y]?
						voxel = @grid.zLayers[z][x][y]
						material = coloring.getMaterialForVoxel voxel
						threeBrick = @geometryCreator.getVoxel {x: x, y: y, z: z}, material
						@voxelsSubnode.add threeBrick

	updateBricks: (@bricks) =>
		return
		
	updateBrickVisualization: (coloring = @defaultColoring) =>
		return






