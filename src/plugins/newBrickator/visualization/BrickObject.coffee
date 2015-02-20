THREE = require 'three'
module.exports = class BrickObject extends THREE.Object3D
	constructor: (brickGeometry, knobGeometry, material) ->
		super()
		@material = material
		brickMesh = new THREE.Mesh(brickGeometry, material)
		knobMesh = new THREE.Mesh(knobGeometry, material)
		@add brickMesh
		@add knobMesh

	setMaterial: (@material) =>
		@children[0].material = @material
		@children[1].material = @material

	setKnobVisibility: (boolean) =>
		@children[1].visible = boolean

	setVoxelCoords: (@voxelCoords) =>
		# stores a reference of this bricks voxel coordinates for
		# further usage
		return

	setGridReference: (@gridEntry) =>
		return

	disable: () =>
		# makes the voxel being 3d printed
		@gridEntry.enabled = false

	enable: () =>
		# makes the voxel being legotized
		@gridEntry.enabled = true

	isEnabled: () =>
		return @gridEntry.enabled

	setHighlight: (isHighlighted, material) =>
		# one may highlight this brick with a special material
		if isHighlighted
			@children[0].material = material
			@children[1].material = material
		else
			@children[0].material = @material
			@children[1].material = @material
