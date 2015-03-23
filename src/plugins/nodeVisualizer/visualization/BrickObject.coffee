THREE = require 'three'
###
# @class BrickObject
###
class BrickObject extends THREE.Object3D
	constructor: (brickGeometry, studGeometry, @material) ->
		super()
		brickMesh = new THREE.Mesh(brickGeometry, @material)
		studMesh = new THREE.Mesh(studGeometry, @material)
		@add brickMesh
		@add studMesh

	setMaterial: (@material) =>
		@children[0].material = @material
		@children[1].material = @material

		# material override resets highlight state
		@_isHighlighted = false

	setStudVisibility: (boolean) =>
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
	make3dPrinted: =>
		@gridEntry.enabled = false
		@nonHighlightVisibility = false

	# makes the voxel being legotized
	makeLego: =>
		@gridEntry.enabled = true
		@nonHighlightVisibility = true

	isLego: =>
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

module.exports = BrickObject
