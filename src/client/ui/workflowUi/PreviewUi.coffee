PreviewAssemblyUi = require './PreviewAssemblyUi'

class PreviewUi
	constructor: (@workflowUi) ->
		@$panel = $('#previewGroup')
		bundle = @workflowUi.bundle
		@nodeVisualizer = bundle.getPlugin 'nodeVisualizer'
		@editController = bundle.getPlugin 'editController'
		@sceneManager = bundle.sceneManager
		@_initStabilityView()
		@_initAssemblyView()

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel, h4').toggleClass 'disabled', !enabled
		@quit() unless enabled

	quit: =>
		@_quitStabilityView() if @stabilityViewEnabled
		@_quitAssemblyView() if @assemblyViewEnabled

	_initStabilityView: =>
		@stabilityViewEnabled = no
		@$stabilityViewButton = $('#stabilityCheckButton')
		@$stabilityViewButton.click =>
			@toggleStabilityView()
			@workflowUi.hideMenuIfPossible()

	_quitStabilityView: =>
		@$stabilityViewButton.removeClass 'active disabled'
		@stabilityViewEnabled = no
		@editController.enableInteraction()

	toggleStabilityView: =>
		@stabilityViewEnabled = !@stabilityViewEnabled
		@_quitAssemblyView()

		if @stabilityViewEnabled
			@workflowUi.enableOnly @
		else
			@workflowUi.enableAll()

		@$stabilityViewButton.toggleClass 'active', @stabilityViewEnabled
		@$assemblyViewButton.toggleClass 'disabled', @stabilityViewEnabled

		if @stabilityViewEnabled
			@editController.disableInteraction()
			@nodeVisualizer.setDisplayMode @sceneManager.selectedNode, 'stability'
		else
			@editController.enableInteraction()

	_initAssemblyView: =>
		@assemblyViewEnabled = no
		@$assemblyViewButton = $('#buildButton')
		@$assemblyViewButton.click @toggleAssemblyView
		@previewAssemblyUi = new PreviewAssemblyUi @

	_quitAssemblyView: =>
		@$assemblyViewButton.removeClass 'active disabled'
		@assemblyViewEnabled = no
		@previewAssemblyUi.setEnabled no
		@editController.enableInteraction()

	toggleAssemblyView: =>
		@assemblyViewEnabled = !@assemblyViewEnabled
		@_quitStabilityView()

		if @assemblyViewEnabled
			@workflowUi.enableOnly @
		else
			@workflowUi.enableAll()

		@$assemblyViewButton.toggleClass 'active', @assemblyViewEnabled
		@$stabilityViewButton.toggleClass 'disabled', @assemblyViewEnabled

		@previewAssemblyUi.setEnabled @assemblyViewEnabled

		if @assemblyViewEnabled
			@editController.disableInteraction()
		else
			@editController.enableInteraction()

module.exports = PreviewUi
