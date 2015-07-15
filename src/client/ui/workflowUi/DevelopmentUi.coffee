class DevelopmentUi
	constructor: (@workflowUi) ->
		@$panel = $('#developmentGroup')
		@bundle = @workflowUi.bundle

		@_initFidelityButtons()

	_initFidelityButtons: =>
		fidelityControl = @bundle.getPlugin 'fidelity-control'

		bIncrease = @$panel.find('#fidelityIncrease')
		bIncrease.click =>
			console.log 'Increase!'
			fidelityControl._manualIncrease()

		bIncrease = @$panel.find('#fidelityDecrease')
		bIncrease.click =>
			console.log 'Decrease!'
			fidelityControl._manualDecrease()

	# development ui is always enabled
	setEnabled: (enabled) => return

	onNodeSelect: (node) => return

	onNodeDeselect: (node) => return

module.exports = DevelopmentUi
