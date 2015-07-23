EditBrushUi = require './EditBrushUi'

class EditUi
	constructor: (@workflowUi) ->
		@$panel = $('#editGroup')
		@bundle = @workflowUi.bundle

		@_initPartList()
		@_initBrushes()

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel, h4, .estimate, #editControls')
		.toggleClass 'disabled', !enabled

	_initBrushes: =>
		@brushUi = new EditBrushUi @workflowUi
		@brushUi.init '#brushContainer', '#bigBrushContainer'

	_initPartList: =>
		@legoInstructions = @bundle.getPlugin 'lego-instructions'
		return if not @legoInstructions?

		$('#brickCountContainer').click =>
			return unless @bundle.sceneManager.selectedNode?
			@legoInstructions.showPartListPopup @bundle.sceneManager.selectedNode

	onNodeSelect: (node) =>
		@brushUi.onNodeSelect node

	onNodeDeselect: (node) =>
		@brushUi.onNodeDeselect node

module.exports = EditUi
