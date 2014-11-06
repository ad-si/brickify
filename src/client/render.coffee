renderQueue = []
uiInstance = null

localRenderer = () ->
	requestAnimationFrame localRenderer
	uiInstance.renderer.render uiInstance.scene, uiInstance.camera

	for plugin in renderQueue
		plugin.update3d()

module.exports.init = (ui) ->
	uiInstance = ui
	localRenderer()

module.exports.addToRenderQueue = (plugin) ->
	renderQueue.push plugin
