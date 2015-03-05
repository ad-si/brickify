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
