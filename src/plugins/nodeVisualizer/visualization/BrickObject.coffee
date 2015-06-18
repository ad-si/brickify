THREE = require 'three'
###
# @class BrickObject
###
class BrickObject extends THREE.Object3D
	constructor: (brickGeometry, studGeometry, planeGeometry,
								@material, @textureMaterial, fidelity) ->
		super()
		brickMesh = new THREE.Mesh(brickGeometry, @material)
		studMesh = new THREE.Mesh(studGeometry, @material)
		planeMesh = new THREE.Mesh(planeGeometry, @textureMaterial)
		@add brickMesh
		@add studMesh
		@add planeMesh
		@setFidelity fidelity

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

	setFidelity: (fidelity) =>
		@children[1].visible = fidelity is 1
		@children[2].visible = fidelity is 0
		#@children[3].visible = fidelity is 2

module.exports = BrickObject
