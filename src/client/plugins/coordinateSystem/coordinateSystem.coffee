###
  #Coordinate System Plugin#

  Creates a colored coordinate system and a grid base surface for better
  navigation inside lowfab.
###

THREE = require 'three'

# Require sub-modules, see [Grid](grid.html) and [Axis](axis.html)
setupGrid = require './grid'
setupAxis = require './axis'

module.exports = class CoordinateSystem
	# Store the global configuration for later use by init3d
	init: (@globalConfig) ->
		return

	# Generate the grid and the axis on 3d scene initialization
	init3d: (threejsNode) ->
		setupGrid(threejsNode, @globalConfig)
		setupAxis(threejsNode, @globalConfig)
