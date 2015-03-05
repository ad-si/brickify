DownloadProvider = require './downloadProvider'
UiObjects = require './objects'

module.exports = class WorkflowUi
	constructor: (@bundle) ->
		@downloadProvider = new DownloadProvider(@bundle)
		@objects = new UiObjects(@bundle)

	init: () =>
		@sceneManager = @bundle.ui.sceneManager
		@downloadProvider.init('#downloadButton', @sceneManager)
		@objects.init('#objectsContainer', '#brushContainer', '#visibilityContainer')
		@_initStabilityCheck()

	_initStabilityCheck: () =>
		@newBrickator = @bundle.getPlugin 'newBrickator'

		$('#stabilityCheckButton').on 'click', () =>
			if $('#stabilityCheckButton').hasClass 'active'
				$('#stabilityCheckButton').removeClass 'active'
			else
				$('#stabilityCheckButton').addClass 'active'
				
			@newBrickator._toggleStabilityView @sceneManager.selectedNode

