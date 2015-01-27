THREE = require 'three'

module.exports = class BrickVisualizer
	constructor: () ->
		@brickMaterial = new THREE.MeshLambertMaterial({
			color: 0xAAAA00
			opacity: 0.8
			transparent: true
		})

	# expects a three node, an array of lego bricks (with positions in)
	# grid coordinates, and optionally a grid offset
	createVisibleBricks: (threeNode, legoArray, settings) =>
		@gridSpacing = settings.gridSpacing
		@gridOffset = settings.gridOffset

		for brick in legoArray
			@brickGeometry = new THREE.BoxGeometry(
				@gridSpacing.x, @gridSpacing.y, @gridSpacing.z
			)
			cube = new THREE.Mesh( @brickGeometry, @brickMaterial )
			cube.translateX( @gridOffset.x + @gridSpacing.x * brick.x)
			cube.translateY( @gridOffset.y + @gridSpacing.y * brick.y)
			cube.translateZ( @gridOffset.z + @gridSpacing.z * brick.z)
			threeNode.add(cube)
