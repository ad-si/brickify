module.exports  = class PipelineSettings
	constructor: ->
		@gridSpacing = {
			x: 8
			y: 8
			z: 3.2
		}
		@gridOffset = {
			x: 0
			y: 0
			z: 0
		}
	setGridSpacing: (x, y, z) =>
		@gridSpacing.x = x
		@gridSpacing.y = y
		@gridSpacing.z = z

	setGridOffset: (x, y, z) =>
		@gridOffset.x = x
		@gridOffset.y = y
		@gridOffset.z = z
