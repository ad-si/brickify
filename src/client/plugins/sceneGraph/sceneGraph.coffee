###
  # Scene Graph Plugin

  Renders interactive scene graph tree in sceneGraphContainer
###

common = require '../../../common/pluginCommon'

module.exports.pluginName = 'Scene Graph'
module.exports.category = common.CATEGORY_RENDERER

# Store the global configuration for later use by init3d
module.exports.init = (globalConfig, state, ui) ->
    @globalConfig = globalConfig

module.exports.initUi = (elements) ->
    elements.sceneGraphContainer.innerHTML = 'Scene Graph'
