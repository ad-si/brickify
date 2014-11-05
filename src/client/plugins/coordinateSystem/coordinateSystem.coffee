common = require '../../../common/pluginCommon'

setupGrid = require './grid'
setupAxis = require './axis'

globalConfigInstance = null

module.exports.pluginName = 'Coordinate System Plugin'
module.exports.category = common.CATEGORY_RENDERER

module.exports.init = (globalConfig, state, ui) ->
	globalConfigInstance = globalConfig

module.exports.init3d = (threejsNode) ->
	setupGrid(threejsNode, globalConfigInstance)
	setupAxis(threejsNode, globalConfigInstance)

module.exports.needs3dAnimation = false
module.exports.update3d = () ->
module.exports.handleStateChange = () ->
