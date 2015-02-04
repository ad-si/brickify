module.exports = class VisibilityMenu
	constructor: (@bundle) ->
		@_layers = []
		@_visibilityContainer = $('#visibilityContainer')
		@_initUi()

	_initUi: =>
		layers = @bundle.pluginHooks.getVisibilityLayers()

		for layerArray in layers
			for layer in layerArray
				layer.enabled = true
				@_layers.push layer
				@_createLayerUi layer, (@_layers.length - 1)

	_createLayerUi: (layer, id) =>
		html = "<div class=\"checkbox\"><label>
			<input id=\"visibleLayer#{id}\"type=\"checkbox\" checked>
			#{layer.text}</label></div>"
		htmlElement = $(html)
		@_visibilityContainer.append htmlElement

		$("#visibleLayer#{id}").change () =>
			layer.enabled = !layer.enabled
			layer.callback layer.enabled
