EditBrushUi = require './EditBrushUi'

class EditUi
	constructor: (@workflowUi) ->
		@$panel = $('#editGroup')
		@_initBrushes()

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel, h4').toggleClass 'disabled', !enabled

	_initBrushes: =>
		@brushUi = new EditBrushUi @workflowUi.bundle
		@brushUi.init '#brushContainer', '#bigBrushContainer'

	onNodeSelect: (node) =>
		@brushUi.onNodeSelect node

	onNodeDeselect: (node) =>
		@brushUi.onNodeDeselect node

module.exports = EditUi
