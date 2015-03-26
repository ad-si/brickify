PreviewAssemblyUi = require './PreviewAssemblyUi'

class PreviewUi
	constructor: (@workflowUi) ->
		@$panel = $("#previewGroup")
		bundle = @workflowUi.bundle
		@nodeVisualizer = bundle.getPlugin 'nodeVisualizer'
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
		@$stabilityViewButton.click @toggleStabilityView

	_quitStabilityView: =>
		@$stabilityViewButton.removeClass 'active disabled'
		@stabilityViewEnabled = no
		@nodeVisualizer.setStabilityView @sceneManager.selectedNode, false

	toggleStabilityView: =>
		@stabilityViewEnabled = !@stabilityViewEnabled

		if @stabilityViewEnabled
			@workflowUi.enableOnly @
		else
			@workflowUi.enableAll()

		@$stabilityViewButton.toggleClass 'active', @stabilityViewEnabled
		@$assemblyViewButton.toggleClass 'disabled', @stabilityViewEnabled

		@nodeVisualizer.setStabilityView(
			@sceneManager.selectedNode, @stabilityViewEnabled
		)

	_initAssemblyView: =>
		@assemblyViewEnabled = no
		@$assemblyViewButton = $('#buildButton')
		@$assemblyViewButton.click @_toggleAssemblyView
		@previewAssemblyUi = new PreviewAssemblyUi @

	_quitAssemblyView: =>
		@$assemblyViewButton.removeClass 'active disabled'
		@assemblyViewEnabled = no
		@previewAssemblyUi.setEnabled no

	_toggleAssemblyView: =>
		@assemblyViewEnabled = !@assemblyViewEnabled

		if @assemblyViewEnabled
			@workflowUi.enableOnly @
		else
			@workflowUi.enableAll()

		@$assemblyViewButton.toggleClass 'active', @assemblyViewEnabled
		@$stabilityViewButton.toggleClass 'disabled', @assemblyViewEnabled

		@previewAssemblyUi.setEnabled @assemblyViewEnabled

module.exports = PreviewUi
