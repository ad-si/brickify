Coloring = require './Coloring'

module.exports = class StabilityColoring extends Coloring
	constructor: ->
		@_createStabilityMaterials()

	_createStabilityMaterials: =>
		@_stabilityMaterials = []
		# 2 by 10 is the largest LEGO brick we support so an array of 21 suffices
		# to reflect all stability shades
		for i in [0..20] by 1
			red = Math.round(255 - i * 255 / 20) * 0x10000
			green = Math.round(i * 255 / 20) * 0x100
			blue = 0
			color = red + green + blue
			# opacity is between 0.75 (perfectly stable) and 1 (not stable at all)
			opacity = if i == 0 then 1 else 1 - i * 0.02
			@_stabilityMaterials.push @_createMaterial(color, opacity)

	getMaterialForBrick: (brick) =>
		index = Math.round brick.getStability() * 19
		@_stabilityMaterials[index]
