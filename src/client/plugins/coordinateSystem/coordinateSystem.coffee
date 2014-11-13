###
  #Coordinate System Plugin#

  Creates a colored coordinate system and a grid base surface for better
  navigation inside lowfab.
###

common = require '../../../common/pluginCommon'

module.exports.pluginName = 'Coordinate System Plugin'
module.exports.category = common.CATEGORY_RENDERER

# Require sub-modules, see [Grid](grid.html) and [Axis](axis.html)
setupGrid = require './grid'
setupAxis = require './axis'

# Store the global configuration for later use by init3d
module.exports.init = (globalConfig, state, ui) ->
	@globalConfig = globalConfig

# Generate the grid and the axis on 3d scene initialization
module.exports.init3D = (threejsNode) ->
	setupGrid(threejsNode, @globalConfig)
	setupAxis(threejsNode, @globalConfig)
