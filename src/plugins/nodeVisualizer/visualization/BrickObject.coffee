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

		@areStudsVisible = true

		@add new THREE.Mesh brickGeometry, @materials.color
		@add new THREE.Mesh studGeometry, @materials.colorStuds
		@add new THREE.Mesh highFiStudGeometry, @materials.colorStuds
		@add new THREE.Mesh planeGeometry, @materials.textureStuds

		@setFidelity fidelity

	setBrick: (@brick) => return
	getBrick: => return @brick
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
		@children[1].visible = fidelity is 1 and @areStudsVisible
		@children[2].visible = fidelity is 2 and @areStudsVisible
		@children[3].visible = fidelity is 0 and @areStudsVisible

	setStudVisibility: (@areStudsVisible) =>
		@children[1].visible = @areStudsVisible
		@children[2].visible = @areStudsVisible
		@children[3].visible = @areStudsVisible

module.exports = BrickObject
