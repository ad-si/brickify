THREE = require 'three'
module.exports = class BrickObject extends THREE.Object3D
	constructor: (brickGeometry, knobGeometry, material) ->
		super()
		@material = material
		brickMesh = new THREE.Mesh(brickGeometry, material)
		knobMesh = new THREE.Mesh(knobGeometry, material)
		@add brickMesh
		@add knobMesh
		@selectable = true
		@_isHighlighted = false

	setMaterial: (@material) =>
		@children[0].material = @material
		@children[1].material = @material
		# material override resets highlight state
		@_isHighlighted = false

	setKnobVisibility: (boolean) =>
		@children[1].visible = boolean

	setSelectable: (boolean) =>
		@selectable = boolean

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
		if isHighlighted and not @_isHighlighted
			@_isHighlighted = true
			@_beforeHighlightVisibility = @visible
			@visible = true
			@children[0].material = material
			@children[1].material = material
		else if @_isHighlighted
			@_isHighlighted = false
			@visible = @_beforeHighlightVisibility if @_beforeHighlightVisibility?
			@children[0].material = @material
			@children[1].material = @material
