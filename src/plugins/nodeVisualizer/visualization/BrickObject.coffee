THREE = require 'three'
###
# @class BrickObject
###
class BrickObject extends THREE.Object3D
	constructor: (geometries, @materials, fidelity) ->
		super()
		{
			brickGeometry
			studGeometry
			highFiStudGeometry
			planeGeometry
		} = geometries

		@add new THREE.Mesh brickGeometry, @materials.color
		@add new THREE.Mesh studGeometry, @materials.colorStuds
		@add new THREE.Mesh highFiStudGeometry, @materials.colorStuds
		@add new THREE.Mesh planeGeometry, @materials.textureStuds

		@setFidelity fidelity

	setMaterial: (@materials) =>
		@children[0].material = @materials.color
		@children[1].material = @materials.colorStuds
		@children[2].material = @materials.colorStuds

	setGray: (isGray) =>
		if isGray
			@children[0].material = @materials.gray
			@children[1].material = @materials.grayStuds
			@children[2].material = @materials.grayStuds
		else
			@children[0].material = @materials.color
			@children[1].material = @materials.colorStuds
			@children[2].material = @materials.colorStuds

	setFidelity: (fidelity) =>
		@children[1].visible = fidelity is 1
		@children[2].visible = fidelity is 2
		@children[3].visible = fidelity is 0

module.exports = BrickObject
