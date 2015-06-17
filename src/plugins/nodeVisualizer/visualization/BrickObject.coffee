THREE = require 'three'
###
# @class BrickObject
###
class BrickObject extends THREE.Object3D
	constructor: (brickGeometry, studGeometry, planeGeometry,
								@material, @textureMaterial, highFidelity) ->
		super()
		brickMesh = new THREE.Mesh(brickGeometry, @material)
		studMesh = new THREE.Mesh(studGeometry, @material)
		planeMesh = new THREE.Mesh(planeGeometry, @textureMaterial)
		@add brickMesh
		@add studMesh
		@add planeMesh
		@_updateQuality highFidelity

	setMaterial: (@material) =>
		@children[0].material = @material
		@children[1].material = @material

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

	# makes the voxel being legotized
	makeLego: =>
		@gridEntry.enabled = true

	isLego: =>
		return @gridEntry.enabled

	setFidelity: (highFidelity) =>
		@_updateQuality highFidelity

	_updateQuality: (highFidelity) =>
		@children[1].visible = highFidelity
		@children[2].visible = !highFidelity

module.exports = BrickObject
