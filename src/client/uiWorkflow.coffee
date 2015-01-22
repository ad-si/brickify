jsonEditorConfiguration = {
	theme: 'bootstrap3'
	disable_array_add: true
	disable_array_delete: true
	disable_array_reorder: true
	disable_collapse: true
	disable_edit_json: true
	disable_properties: true
}

module.exports = class UiWorkflow
	constructor: (@bundle) ->
		@plugins = @bundle.getPlugins('converter').map @_loadPlugin
		console.log @plugins
		return

	showSplit: (node) ->
		# TODO
		return

	showConvert: (node) ->
		# build convert ui for node's selected plugin if not already done
		# set stored values if present or default values if not
		# show plugin ui
		# update plugin selection in convert
		return

	showExport: (node) ->
		# build export ui for node's selected plugin if not already done and if
		# plugin provides an export ui
		# build download button for plugins that do not provide an export ui
		# show export ui
		return

	_loadPlugin: (plugin) =>
		# TODO get split hinting
		convertSchema = plugin.getConvertUiSchema()
		# TODO get export mode / schema
		return {
			convertSchema
		}
