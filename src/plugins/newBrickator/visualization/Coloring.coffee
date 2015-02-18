# Provides an simple implementation on how to color bricks
module.exports = class Coloring
	constructor: () ->
		@brickMaterial = new THREE.MeshLambertMaterial({
			color: 0xfff000 #orange
		})

		@selectedMaterial = new THREE.MeshLambertMaterial({
			color: 0xff0000
		})

		@deselectedMaterial = new THREE.MeshLambertMaterial({
			color: 0xb5ffb8 #greenish gray
			opacity: 0.8
			transparent: true
		})

		@hiddenMaterial = new THREE.MeshLambertMaterial({
			color: 0xffaaaa #gray
			opacity: 0.0
			transparent: true
		})

	getMaterialForVoxel: (gridEntry) =>
		if gridEntry.enabled
			return @selectedMaterial
		else
			return @hiddenMaterial

	getMaterialForBrick: (brick) =>
		return @brickMaterial
