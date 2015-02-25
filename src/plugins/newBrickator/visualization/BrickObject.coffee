THREE = require 'three'
module.exports = class BrickObject extends THREE.Object3D
	constructor: (brickGeometry, knobGeometry, material) ->
		super()
		@material = material
		brickMesh = new THREE.Mesh(brickGeometry, material)
		knobMesh = new THREE.Mesh(knobGeometry, material)
		@add brickMesh
		@add knobMesh
		@raycasterSelectable = true
		@_isHighlighted = false

	setMaterial: (@material) =>
		@children[0].material = @material
		@children[1].material = @material

		# material override resets highlight state
		@_isHighlighted = false

	setKnobVisibility: (boolean) =>
		@children[1].visible = boolean

	# If the object is not visible, it can still be selected by the
	# raycaster in NodeVisualization.getVoxel if it is raycasterSelectable
	# (visible objects can always be selected by the raycaster)
	setRaycasterSelectable: (boolean) =>
		@raycasterSelectable = boolean

	# stores a reference of this bricks voxel coordinates for
	# further usage
	setVoxelCoords: (@voxelCoords) =>
		return

	setGridReference: (@gridEntry) =>
		return

	# makes the voxel being 3d printed
	disable: () =>
		@gridEntry.enabled = false

	# makes the voxel being legotized
	enable: () =>
		@gridEntry.enabled = true

	isEnabled: () =>
		return @gridEntry.enabled

	# one may highlight this brick with a special material
	setHighlight: (isHighlighted, material) =>
		if isHighlighted and not @_isHighlighted
			@_isHighlighted = true
			@_beforeHighlightVisibility = @visible
			@visible = true
			@children[0].material = material
			@children[1].material = material
		else if (not isHighlighted) and @_isHighlighted
			@_isHighlighted = false
			@visible = @_beforeHighlightVisibility if @_beforeHighlightVisibility?
			@children[0].material = @material
			@children[1].material = @material
