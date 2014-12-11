$ = require 'jquery'
objectTree = require '../common/objectTree'

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
		@pluginContainers = {}
		@editors = {}
		@defaultValues = {}
		@currentlySelectedNode = null
		return

	createPluginUi: (pluginInstance) ->
		# creates the UI for a plugin if it returns a valid ui schema
		jsonEditorConfiguration.schema = pluginInstance.getUiSchema()
		if jsonEditorConfiguration.schema
			$pluginsContainer = $('#pluginsContainer')
			if $pluginsContainer.length > 0
				key = pluginInstance.name

				$pluginContainer = $("<div id='#{key}'></div>")
				$pluginsContainer.append($pluginContainer)

				@pluginContainers[key] = $pluginContainer
				@editors[key] = new JSONEditor(
					$pluginContainer[0]
					jsonEditorConfiguration
				)
				@defaultValues[key] = @editors[key].getValue()

				@editors[key].on 'change',() =>
					@saveUiToCurrentNode()

	selectNode: (modelName) ->
		# is called by the scenegraph plugin when the user selects a model on the
		# left. allows to make plugin values relative to objects
		console.log "Selecting node #{modelName}"

		@bundle.statesync.getState (state) =>
			objectTree.getNodeByFileName modelName, state.rootNode, (node) =>
				@currentlySelectedNode = node
				@saveDefaultValues node
				@applyNodeValuesToUi()

	deselectNodes: () ->
		#called when all nodes are deselected
		console.log 'all nodes deselected'
		@currentlySelectedNode = null

	applyNodeValuesToUi: () =>
		for key of @editors
			@editors[key].setValue(@currentlySelectedNode.toolsValues[key])

	saveUiToCurrentNode: () =>
		if @currentlySelectedNode
			action = () =>
				for key of @editors
					@currentlySelectedNode.toolsValues[key] = @editors[key].getValue()

			@bundle.statesync.performStateAction action, true

	saveDefaultValues: (node) =>
		if not node.toolsValues
			node.toolsValues = {}
		for key of @editors
			if not node.toolsValues[key]
				node.toolsValues[key] = @defaultValues[key]
