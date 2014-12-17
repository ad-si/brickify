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

pluginUiTemplate = '
			<div class="panel panel-default">
				<div class="panel-heading">
					<h3 class="collapseTitle collapsed panel-title"
data-toggle="collapse" data-parent="#pluginsContainer"
data-target="#collapse%PLUGINKEY%">%PLUGINNAME%</h3>
				</div>
				<div id="collapse%PLUGINKEY%" class="panel-collapse collapse">
					<div class="panel-body">
						<div id="pactions%PLUGINKEY%" class="pluginActionsContainer"></div>
						<div id="pcontainer%PLUGINKEY%" class="pluginSettingsContainer"></div>
					</div>
				</div>
			</div>
'

module.exports = class PluginUiGenerator
	constructor: (@bundle) ->
		@editors = {}
		@defaultValues = {}
		@pluginLayouts = []
		@currentlySelectedNode = null
		@$pluginsContainer = $('#pluginsContainer')
		@$pluginsContainer.hide()
		@currentlyEnabledPlugin = null
		return

	createPluginUi: (pluginInstance) ->
		# creates the UI for a plugin if it returns a valid ui schema
		jsonEditorConfiguration.schema = pluginInstance.getUiSchema()
		if jsonEditorConfiguration.schema && @$pluginsContainer.length > 0
			pluginName = pluginInstance.name
			pluginKey = pluginName.toLowerCase().replace(/// ///g,'')

			pluginLayout = pluginUiTemplate
			pluginLayout = pluginLayout.replace(///%PLUGINKEY%///g,pluginKey)
			pluginLayout = pluginLayout.replace(///%PLUGINNAME%///g,pluginName)

			$pluginLayout = $(pluginLayout)
			@$pluginsContainer.append($pluginLayout)
			$pluginSettingsContainer = $('#pcontainer' + pluginKey)
			$pluginActionContainer = $('#pactions' + pluginKey)

			@generateActionUi jsonEditorConfiguration.schema, $pluginActionContainer
			@editors[pluginKey] = new JSONEditor(
				$pluginSettingsContainer[0]
				jsonEditorConfiguration
			)
			@defaultValues[pluginKey] = @editors[pluginKey].getValue()

			@editors[pluginKey].on 'change',() =>
				@saveUiToCurrentNode()

			# when the panel is collapsed
			$pluginLayout.on 'hidden.bs.collapse', (event) =>
				@currentlyEnabledPlugin = null

				if pluginInstance.uiDisabled?
					pluginInstance.uiDisabled @currentlySelectedNode

			# when the panel is opened
			$pluginLayout.on 'shown.bs.collapse', (event) =>
				@currentlyEnabledPlugin = pluginInstance

				if pluginInstance.uiEnabled?
					pluginInstance.uiEnabled @currentlySelectedNode

			@pluginLayouts.push {
				collapse: $('#collapse' + pluginKey)
				pluginInstance: pluginInstance
			}

	generateActionUi: (schema, $container) ->
		if schema.actions?
			for own key of schema.actions
				title = schema.actions[key].title
				type = schema.actions[key].type or 'primary'
				$btn =
					$('<div class="actionbutton btn btn-' + type + '">' + title + '</div>')
				$btn.click (event) ->
					schema.actions[key].callback @currentlySelectedNode, event
				$container.append $btn

	selectPluginUi: (pluginName) ->
		# for whatever reason, accordion items first have to be shown, then
		# other items have to be hidden. mixed actions cause bugs
		pluginsToHide = []

		for l in @pluginLayouts
			if l.pluginInstance.name == pluginName
				l.collapse.collapse 'show'
			else
					if l.collapse.hasClass 'in'
						pluginsToHide.push l
		for l in pluginsToHide
			l.collapse.collapse 'hide'

	selectNode: (modelName) ->
		# is called by the scenegraph plugin when the user selects a model on the
		# left. allows to make plugin values relative to objects
		# console.log "Selecting node #{modelName}"

		if @currentlySelectedNode
			@currentlySelectedNode.pluginData.uiGen = {}
			if @currentlyEnabledPlugin?
				@currentlySelectedNode.pluginData.uiGen.selectedPluginName =
					@currentlyEnabledPlugin.name
			else
				@currentlySelectedNode.pluginData.uiGen.selectedPluginName =
					''

		if modelName == 'Scene'
			@$pluginsContainer.hide()
			@currentlySelectedNode = null
			return

		@bundle.statesync.getState (state) =>
			objectTree.getNodeByFileName modelName, state.rootNode, (node) =>
				@currentlySelectedNode = node
				@saveDefaultValues node
				@applyNodeValuesToUi()

				if node.pluginData.uiGen?
					@selectPluginUi node.pluginData.uiGen.selectedPluginName
				else
					node.pluginData.uiGen = {}
					node.pluginData.uiGen.selectedPluginName = ''
					@selectPluginUi null

				@$pluginsContainer.show()

	deselectNodes: () ->
		# called when all nodes are deselected
		#console.log 'all nodes deselected'
		@currentlySelectedNode = null
		@$pluginsContainer.hide()

	applyNodeValuesToUi: () =>
		for own key of @editors
			@editors[key].setValue(@currentlySelectedNode.toolsValues[key])

	saveUiToCurrentNode: () =>
		if @currentlySelectedNode
			for own key of @editors
				oldValues = @currentlySelectedNode.toolsValues[key]
				newValues = @editors[key].getValue()

				if JSON.stringify(oldValues) != JSON.stringify(newValues)
					updateNewValues = () =>
						@currentlySelectedNode.toolsValues[key] = newValues
					@bundle.statesync.performStateAction updateNewValues, true

	saveDefaultValues: (node) =>
		if not node.toolsValues
			node.toolsValues = {}
		for key of @editors
			if not node.toolsValues[key]
				node.toolsValues[key] = @defaultValues[key]
