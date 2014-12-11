$ = require 'jquery'

jsonEditorConfiguration = {
	theme: 'bootstrap3'
	disable_array_add: true
	disable_array_delete: true
	disable_array_reorder: true
	disable_collapse: true
	disable_edit_json: true
	disable_properties: true
}

module.exports = class PluginUiGenerator
	constructor: (@bundle) ->
		return

	createPluginUi: (pluginInstance) ->
		jsonEditorConfiguration.schema = pluginInstance.getUiSchema()
		if jsonEditorConfiguration.schema
			$pluginsContainer = $('#pluginsContainer')
			if $pluginsContainer.length > 0
				$pluginContainer = $("<div id='#{pluginInstance.name}'></div>")
				$pluginsContainer.append($pluginContainer)
				editor = new JSONEditor(
					$pluginContainer[0]
					jsonEditorConfiguration
				)

				editor.on 'change',() =>
					action = (state) ->
						state.toolsValues = editor.getValue()
					@bundle.statesync.performStateAction action, true
