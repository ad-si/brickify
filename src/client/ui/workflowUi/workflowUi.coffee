DownloadProvider = require './downloadProvider'
UiObjects = require './objects'

module.exports = class WorkflowUi
	constructor: (@bundle) ->
		@downloadProvider = new DownloadProvider(@bundle)
		@objects = new UiObjects(@bundle)

	init: () =>
		@sceneManager = @bundle.sceneManager
		@downloadProvider.init('#downloadButton', @sceneManager)
		@objects.init('#objectsContainer', '#brushContainer', '#visibilityContainer')
		@_initStabilityCheck()
		@_initNotImplementedMessages()

	_initStabilityCheck: () =>
		@newBrickator = @bundle.getPlugin 'newBrickator'

		$('#stabilityCheckButton').on 'click', () =>
			if $('#stabilityCheckButton').hasClass 'active'
				$('#stabilityCheckButton').removeClass 'active'
			else
				$('#stabilityCheckButton').addClass 'active'
				
			@newBrickator._toggleStabilityView @sceneManager.selectedNode

	_initNotImplementedMessages: () =>
		alertCallback = () ->
			bootbox.alert({
					title: 'Not implemented yet'
					message: 'We are sorry, but this feature is not implemented yet.
					 Please check back later.'
			})

		$('#everythingPrinted').click alertCallback
		$('#everythingLego').click alertCallback
		$('#downloadPdfButton').click alertCallback
		$('#shareButton').click alertCallback


