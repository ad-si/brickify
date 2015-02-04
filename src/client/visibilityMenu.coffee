module.exports = class VisibilityMenu
	constructor: (@bundle) ->
		@_layers = @bundle.pluginHooks.getVisibilityLayers().reduce(
			(layers, l) -> layers.concat l
		)

		$container = $('#visibilityContainer')

		for layer in @_layers
			layer.enabled = true
			$container.append @_createLayerUi layer

	_createLayerUi: (layer) =>
		html = "<div class=\"checkbox\">
			<label><input type=\"checkbox\" checked>#{layer.text}</label></div>"
		$htmlElement = $(html)

		$htmlElement.find('input').change () =>
			layer.enabled = !layer.enabled
			layer.callback layer.enabled
		return $htmlElement
