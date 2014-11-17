###
# @module render
###

pluginHooks = require '../common/pluginHooks'
uiInstance = null

localRenderer = () ->
	requestAnimationFrame( localRenderer )
	uiInstance.renderer.render( uiInstance.scene, uiInstance.camera )

	pluginHooks.update3D()

module.exports.init = (ui) ->
	uiInstance = ui
	localRenderer()
