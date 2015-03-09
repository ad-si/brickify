THREE = require 'three'
module.exports = class BrickObject extends THREE.Object3D
	constructor: (brickGeometry, knobGeometry, @material) ->
		super()
		brickMesh = new THREE.Mesh(brickGeometry, @material)
		knobMesh = new THREE.Mesh(knobGeometry, @material)
		@add brickMesh
		@add knobMesh

	setMaterial: (@material) =>
		@children[0].material = @material
		@children[1].material = @material

		# material override resets highlight state
		@_isHighlighted = false

	setKnobVisibility: (boolean) =>
		@children[1].visible = boolean

	# stores a reference of this bricks voxel coordinates for
	# further usage
	setVoxelCoords: (@voxelCoords) =>
		return

	setGridReference: (@gridEntry) =>
		return unless @gridEntry?
		@gridEntry.visibleVoxel = @
		return

	# makes the voxel being 3d printed
	make3dPrinted: () =>
		@gridEntry.enabled = false
		@nonHighlightVisibility = false

	# makes the voxel being legotized
	makeLego: () =>
		@gridEntry.enabled = true
		@nonHighlightVisibility = true

	isLego: () =>
		return @gridEntry.enabled

	# one may highlight this brick with a special material
	setHighlight: (isHighlighted, material) =>
		if isHighlighted
			@visible = true
			@children[0].material = material
			@children[1].material = material
		else
			@visible = @nonHighlightVisibility
			@children[0].material = @material
			@children[1].material = @material
