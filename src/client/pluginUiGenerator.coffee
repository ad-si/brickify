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
				<div class="panel-heading" role="tab">
					<h3 class="panel-title collapsed collapseTitle" data-toggle="collapse"
							data-parent="#pluginsContainer"
							data-target="#collapse%PLUGINKEY%">
						%PLUGINNAME%
					</h3>
				</div>
				<div id="collapse%PLUGINKEY%"
						 class="panel-collapse collapse plugincollapse" role="tabpanel">
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
		@tabStates = {}
		@pluginInstances = {}
		return

	createPluginUi: (pluginInstance) ->
		# creates the UI for a plugin if it returns a valid ui schema
		jsonEditorConfiguration.schema = pluginInstance.getUiSchema()
		if jsonEditorConfiguration.schema && @$pluginsContainer.length > 0
			pluginName = jsonEditorConfiguration.schema.title || pluginInstance.name
			pluginKey = pluginName.toLowerCase().replace(' ','')

			pluginLayout = pluginUiTemplate
			pluginLayout = pluginLayout.replace(///%PLUGINKEY%///g,pluginKey)
			pluginLayout = pluginLayout.replace(///%PLUGINNAME%///g,pluginName)

			$pluginLayout = $(pluginLayout)
			@$pluginsContainer.append($pluginLayout)
			$pluginSettingsContainer = $('#pcontainer' + pluginKey)
			$pluginActionContainer = $('#pactions' + pluginKey)

			@generateActionUi jsonEditorConfiguration.schema,
				pluginKey, $pluginActionContainer
			@editors[pluginKey] = new JSONEditor(
				$pluginSettingsContainer[0]
				jsonEditorConfiguration
			)
			@defaultValues[pluginKey] = @editors[pluginKey].getValue()

			@editors[pluginKey].on 'change',() =>
				@saveUiToCurrentNode()

			@bindPluginUiEvents $pluginLayout, pluginInstance, pluginKey

			@pluginLayouts.push {
				collapse: $('#collapse' + pluginKey)
				pluginInstance: pluginInstance
			}

			@tabStates[pluginKey] = false
			@pluginInstances[pluginKey] = pluginInstance

	bindPluginUiEvents: ($pluginLayout, pluginInstance, pluginKey) =>
			# when the panel is collapsed
			$pluginLayout.on 'hidden.bs.collapse', (event) =>
				@tabStates[pluginKey] = false
				@updateSelectedPlugin()

				#if pluginInstance.uiDisabled?
				#	pluginInstance.uiDisabled @currentlySelectedNode

			# when the panel is opened
			$pluginLayout.on 'shown.bs.collapse', (event) =>
				@tabStates[pluginKey] = true
				@updateSelectedPlugin()

				#if pluginInstance.uiEnabled?
				#	pluginInstance.uiEnabled @currentlySelectedNode

	generateActionUi: (schema, pluginKey, $container) =>
		if schema.actions?
			for own key of schema.actions
				title = schema.actions[key].title
				type = schema.actions[key].type or 'primary'
				id = 'abtn' + pluginKey + key
				@generateButton title,
					type, id, schema.actions[key].callback, $container

	generateButton: (title, type, id, callback, $container) =>
		# extra method necessary because
		# else all buttons will bind to last callback
		$btn =
			$('<div id="' + id +
				'" class="actionbutton btn btn-' + type +
				'">' + title + '</div>')
		$btn.click (event) =>
			callback @currentlySelectedNode, event

		$container.append $btn

	selectPluginUi: (pluginKey) ->
		# collapse all if key is empty
		if not pluginKey or pluginKey.length == 0
			$('#pluginsContainer .collapse.in').collapse 'hide'

		data = $('#collapse' + pluginKey).data('bs.collapse')
		if data
			data.show()
		else
			$('#collapse' + pluginKey).collapse({
				parent: $('#pluginsContainer')
				toggle: true
			})

		# call updatedSelectedPlugin to make sure it is called at least once
		# if there are animations (collapsing in/out), only the last
		# call to updateSelectedPlugin will perform anything
		@updateSelectedPlugin()


	updateSelectedPlugin: () ->
		# don't do anything if we aren't the last panel to close/open
		# (else: redundant state updates)
		if $('#pluginsContainer .collapsing').length > 0
			return

		@disablePluginsIfNecessary()

		# search for the newly activated (=true) plugin
		currentPlugin = @currentlySelectedNode.pluginData.uiGen.selectedPluginKey
		newPlugin = null

		for own pluginKey of @tabStates
			if @tabStates[pluginKey]
				newPlugin = pluginKey
				break

		switchedNode = true if @oldNode != @currentlySelectedNode
		selectedNewPlugin = true if newPlugin and newPlugin != currentPlugin

		if selectedNewPlugin or switchedNode
			@bundle.statesync.performStateAction () =>
				@currentlySelectedNode.pluginData.uiGen.selectedPluginKey = newPlugin
				# send activate event
				@callPluginEnabled @currentlySelectedNode
		else if not newPlugin
			@bundle.statesync.performStateAction () =>
				# console.log "Deselected any plugin"
				@currentlySelectedNode.pluginData.uiGen.selectedPluginKey = ''
				# disable event was already sent earlier

		@oldNode = @currentlySelectedNode

	disablePluginsIfNecessary: () ->
		# either: the user switched the node:
		# send close event to the last active plugin (from the old selected node)
		if @oldNode and @oldNode != @currentlySelectedNode
			@callPluginDisabled @oldNode
			# or he has the same node, but selected another plugin:
			# send close event to the currently selected plugin
		else if @oldNode == @currentlySelectedNode
			@callPluginDisabled @currentlySelectedNode
		# or he selected a node without a node being selected before
		# but then no disabled call has to be made

	callPluginDisabled: (node) ->
		# calls the uiDisabled method on the selected plugin of this node
		pluginKey = node.pluginData.uiGen.selectedPluginKey

		if pluginKey and pluginKey.length > 0
			if @pluginInstances[pluginKey].uiDisabled
				@pluginInstances[pluginKey].uiDisabled node

	callPluginEnabled: (node) ->
		#calls the uiEnabled method on the selected plugin of this node
		pluginKey = node.pluginData.uiGen.selectedPluginKey

		if pluginKey and pluginKey.length > 0
			if @pluginInstances[pluginKey].uiEnabled
				@pluginInstances[pluginKey].uiEnabled node

	onSelectNode: (stateNode) ->
		# is called by the scenegraph plugin when the user selects a model on the
		# left.
		@saveUiToCurrentNode()
		@oldNode = @currentlySelectedNode
		@currentlySelectedNode = stateNode
		@saveDefaultValues stateNode
		@applyNodeValuesToUi()
		@$pluginsContainer.show()

		@selectPluginUi @currentlySelectedNode.pluginData.uiGen.selectedPluginKey

	onDeselectNode: () ->
		# called when all nodes are deselected
		#console.log 'all nodes deselected'
		@saveUiToCurrentNode()
		@callPluginDisabled @currentlySelectedNode
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
					updateNewValues = (node, key, val) => () =>
						node.toolsValues[key] = val
					@bundle.statesync.performStateAction(
						updateNewValues(@currentlySelectedNode, key, newValues), true
					)

	saveDefaultValues: (node) =>
		if not node.toolsValues
			node.toolsValues = {}
		for key of @editors
			if not node.toolsValues[key]
				node.toolsValues[key] = @defaultValues[key]
		if not node.pluginData.uiGen
			node.pluginData.uiGen = {
				selectedPluginKey: ''
			}
