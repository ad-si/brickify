module.exports = class UiWorkflow
	constructor: (@bundle) ->
		@plugins = {}
		for plugin in @bundle.getPlugins('converter').map @_loadPlugin
			@plugins[plugin.name] = plugin
		@showCurrent = @showConvert
		@workflowMenu = $('#workflowMenu')
		@hide()
		return

	hide: () =>
		@workflowMenu.hide()

	showSplit: (node) =>
		# TODO
		@workflowMenu.show()
		@showCurrent = @showSplit
		return

	showConvert: (node) =>
		@$convertMenu ?= $('#convertMenu')
		# remove old convert ui
		@$convertMenu.children().detach()
		# add new convert ui
		# TODO use selected plugin instead of default
		ui = @_getConvertUi(@plugins.newBrickator)
		# set stored values if present or default values if not
		@$convertMenu.append ui
		# update plugin selection in convert
		@workflowMenu.show()
		@showCurrent = @showConvert
		return

	showExport: (node) =>
		# build export ui for node's selected plugin if not already done and if
		# plugin provides an export ui
		# build download button for plugins that do not provide an export ui
		# show export ui
		@workflowMenu.show()
		@showCurrent = @showExport
		return

	_loadPlugin: (pluginInstance) =>
		# TODO get split hinting
		convertSchema = pluginInstance.getConvertUiSchema()
		# TODO get export mode / schema
		return {
			instance: pluginInstance
			name: pluginInstance.name
			schema: convertSchema
		}

	_getConvertUi: (plugin) ->
		return plugin.convertUi ?= @_buildConvertUi(plugin)

	_buildConvertUi: (plugin) ->
		ui = $([])
		ui = ui.add @_buildPropertyUi plugin
		ui = ui.add @_buildActionUi plugin
		return ui

	_buildButton: (title, type, callback) =>
		$btn = $('<div class="btn btn-' + type + '">' + title + '</div>')
		$btn.click (event) => callback @bundle.ui.scene.selectedNode, event
		return $btn

	_buildPropertyUi: (plugin, $container) =>
		return if not plugin.schema.properties

		# creates the UI for a plugin if it returns a valid ui schema
		jsonEditorConfiguration.schema = plugin.schema
		$propertyUi = $('<div></div>')
		new JSONEditor(
			$propertyUi[0]
			jsonEditorConfiguration
		)
		return $propertyUi

	_buildActionUi: (plugin) =>
		return if not plugin.schema.actions?
		$actionUi = $('<div></div>')
		schema = plugin.schema
		for own key of schema.actions
			title = schema.actions[key].title
			type = schema.actions[key].type or 'primary'
			$actionUi.append(
				@_buildButton title, type, schema.actions[key].callback
			)
		return $actionUi

jsonEditorConfiguration = {
	theme: 'bootstrap3'
	disable_array_add: true
	disable_array_delete: true
	disable_array_reorder: true
	disable_collapse: true
	disable_edit_json: true
	disable_properties: true
}
