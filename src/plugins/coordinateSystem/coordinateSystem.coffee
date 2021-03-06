###
  #Coordinate System Plugin#

  Creates a colored coordinate system and a grid base surface for better
  navigation inside brickify.
###

THREE = require 'three'

# Require sub-modules, see [Grid](grid.html) and [Axis](axis.html)
setupGrid = require './grid'
setupAxis = require './axis'

module.exports = class CoordinateSystem
	# Store the global configuration for later use by init3d
	init: (bundle) ->
		@globalConfig = bundle.globalConfig
		return

	# Generate the grid and the axis on 3d scene initialization
	init3d: (@threejsNode) =>
		setupGrid(@threejsNode, @globalConfig)
		setupAxis(@threejsNode, @globalConfig)
		@isVisible = no
		@threejsNode.visible = false

	toggleVisibility: =>
		@threejsNode.visible = !@threejsNode.visible
		@isVisible = !@isVisible

	setFidelity: (fidelityLevel, availableLevels, options) =>
		if options.screenshotMode?
			@threejsNode.visible = @isVisible and not options.screenshotMode
