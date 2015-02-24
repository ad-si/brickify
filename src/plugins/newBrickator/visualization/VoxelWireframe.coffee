THREE = require 'three'
VoxelUnion = require '../VoxelUnion'

# This class creates an wireframe representation of a given set of voxels
module.exports = class VoxelOutline
	constructor: (@grid, threeNode) ->
		@threeNode = new THREE.Object3D()
		threeNode.add @threeNode

		@voxelUnion = new VoxelUnion(@grid)

	setVisibility: (isVisible) =>
		@threeNode.visible = isVisible

	# creates a wireframe out of voxels
	# @param {{x,y,z}[]} voxels
	createWireframe: (voxels) =>
		# clear old representations
		@threeNode.children = []

		# create Geometry
		options = {
			threeBoxGeometryOnly: true
		}
		boxGeometry = @voxelUnion.run voxels, options

		#edge helper to the rescue
		material = new THREE.MeshLambertMaterial({
			color: 0x00ff00
		})
		mesh = new THREE.Mesh(boxGeometry, material)

		edgeHelper = new THREE.EdgesHelper(mesh, 0x000000)
		edgeHelper.material.linewidth = 2
		@threeNode.add edgeHelper
