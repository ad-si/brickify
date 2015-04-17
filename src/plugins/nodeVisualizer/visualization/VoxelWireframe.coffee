THREE = require 'three'
VoxelUnion = require '../../csg/VoxelUnion'
interactionHelper = require '../../../client/interactionHelper'

# This class creates a wireframe representation with darkened sides
# of a given set of voxels
module.exports = class VoxelOutline
	constructor: (@bundle, @grid, threeNode, @coloring) ->
		@threeNode = new THREE.Object3D()
		threeNode.add @threeNode

		@voxelUnion = new VoxelUnion(@grid)

	setVisibility: (isVisible) =>
		@threeNode.visible = isVisible

	isVisible: =>
		return @threeNode.visible

	# creates a wireframe out of voxels
	# @param {Array} voxels array of voxels {x, y, z}[] to create
	# wireframe for
	createWireframe: (voxels) =>
		# clear old representations
		@threeNode.children = []

		# create Geometry
		options = {
			threeBoxGeometryOnly: true
		}
		boxGeometry = @voxelUnion.run voxels, options

		# add black sides to make volume more visible
		shadowBox = new THREE.Mesh(boxGeometry, @coloring.legoShadowMat)
		@threeNode.add shadowBox
		@threeNode.shadowBox = shadowBox

		# add black lines to create a visible outline
		# material is not used, but needs to be provided
		material = new THREE.MeshLambertMaterial({
			color: 0x000000
		})
		mesh = new THREE.Mesh(boxGeometry, material)

		edgeHelper = new THREE.EdgesHelper(mesh, 0x000000, 10)
		edgeHelper.material.linewidth = 2
		@threeNode.add edgeHelper
		@threeNode.edgeHelper = edgeHelper

	# returns the intersections between a ray and the shadowBox geometry
	intersectRay: (event) =>
		intersectObject = @threeNode.shadowBox

		# set two sided material to catch all intersections
		oldMaterialSide = intersectObject.material.side
		intersectObject.material.side = THREE.DoubleSide

		# intersect with ray
		intersects =
			interactionHelper.getIntersections(
				event
				@bundle.renderer
				[intersectObject]
			)

		# apply old material side property
		intersectObject.material.side = oldMaterialSide

		return intersects
