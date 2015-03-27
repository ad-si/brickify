DownloadProvider = require './downloadProvider'

class ExportUi
	constructor: (@workflowUi) ->
		@$panel = $("#exportGroup")
		@_initDownloadButton()

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel, h4').toggleClass 'disabled', !enabled

	_initDownloadButton: =>
		@downloadProvider = new DownloadProvider @workflowUi.bundle
		@downloadProvider.init '#downloadButton', @workflowUi.bundle.sceneManager

module.exports = ExportUi
