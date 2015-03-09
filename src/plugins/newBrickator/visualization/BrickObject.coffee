THREE = require 'three'
module.exports = class BrickObject extends THREE.Object3D
	constructor: (brickGeometry, knobGeometry, material) ->
		super()
		@actualMaterial = material
		brickMesh = new THREE.Mesh(brickGeometry, @actualMaterial)
		knobMesh = new THREE.Mesh(knobGeometry, @actualMaterial)
		@add brickMesh
		@add knobMesh
		@_isHighlighted = false

	setMaterial: (@actualMaterial) =>
		@children[0].material = @actualMaterial
		@children[1].material = @actualMaterial

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
		@correctVisibility = false

	# makes the voxel being legotized
	makeLego: () =>
		@gridEntry.enabled = true
		@correctVisibility = true

	isLego: () =>
		return @gridEntry.enabled

	# one may highlight this brick with a special material
	setHighlight: (isHighlighted, material) =>
		if isHighlighted
			@_isHighlighted = true
			@visible = true
			@children[0].material = material
			@children[1].material = material
		else
			@_isHighlighted = false
			@visible = @correctVisibility
			@children[0].material = @actualMaterial
			@children[1].material = @actualMaterial
