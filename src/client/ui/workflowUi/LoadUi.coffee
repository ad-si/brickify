fileDropper = require '../../modelLoading/fileDropper'
fileLoader = require '../../modelLoading/fileLoader'

class LoadUi
	constructor: (@workflowUi) ->
		@$panel = $('#loadGroup')
		@_initFileLoadHandler()

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel').toggleClass 'disabled', !enabled

	_initFileLoadHandler: =>
		fileDropper.init @fileLoadHandler

		$('#fileInput').on 'change', (event) =>
			@fileLoadHandler event
			$('#fileInput').val('')

	fileLoadHandler: (event) =>
		spinnerOptions =
			length: 5
			radius: 3
			width: 2
			shadow: false
		fileLoader.onLoadFile(
			event
			document.getElementById 'loadButtonFeedback'
			spinnerOptions
		).then @workflowUi.bundle.modelLoader.loadByHash

module.exports = LoadUi
