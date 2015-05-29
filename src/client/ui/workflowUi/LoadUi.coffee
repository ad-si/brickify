fileDropper = require '../../modelLoading/fileDropper'
fileLoader = require '../../modelLoading/fileLoader'
piwikTracking = require '../../piwikTracking'

class LoadUi
	constructor: (@workflowUi) ->
		@$panel = $('#loadGroup')
		@_initFileLoadHandler()

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel').toggleClass 'disabled', !enabled

	_initFileLoadHandler: =>
		fileDropper.init @fileLoadHandler

		$('#fileInput').on 'change', (event) =>
			@fileLoadHandler(event).then =>
				$('#fileInput').val('')
				@workflowUi.hideMenuIfPossible()

	fileLoadHandler: (event) =>
		files = event.target.files ? event.dataTransfer.files
		@_checkReplaceModel().then (loadConfirmed) =>
			return unless loadConfirmed
			piwikTracking.trackEvent 'Editor', 'LoadModel', files[0].name
			spinnerOptions =
				length: 5
				radius: 3
				width: 2
				shadow: false
			fileLoader.onLoadFile(
				files
				document.getElementById 'loadButtonFeedback'
				spinnerOptions
			).then @workflowUi.bundle.modelLoader.loadByHash

	_checkReplaceModel: =>
		question = 'You already have a model in your scene.
				 Loading the new model will replace the existing model!'

		@workflowUi.bundle.sceneManager.scene.then (scene) ->
			return true if scene.nodes.length is 0
			return new Promise (resolve) -> bootbox.confirm question, resolve

module.exports = LoadUi
