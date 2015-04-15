ReadableFileStream = require('filestream').read
meshlib = require 'meshlib'
stlParser = require 'stl-parser'

fileDropper = require '../../modelLoading/fileDropper'
modelCache = require '../../modelLoading/modelCache'


class LoadUi
	constructor: (@workflowUi) ->
		@$panel = $('#loadGroup')
		@_initFileLoadHandler()

	# TODO: Remove code duplication in landingpage.coffee
	readFile: (event, bundles, callback) =>
		event.preventDefault()
		event.stopPropagation()

		if event instanceof MouseEvent
			files = event.dataTransfer.files
		else
			files = event.target.files

		progress = document.querySelector 'progress'
		progress.setAttribute 'value', 0

		@_checkReplaceModel()
		.then (loadConfirmed) =>
			return unless loadConfirmed

			fileStream = new ReadableFileStream files[0]

			fileStream.reader.addEventListener 'progress', (event) ->
				percentageLoaded = 0
				if event.lengthComputable
					percentageLoaded = (event.loaded / event.total).toFixed(2)
					progress.setAttribute 'value', percentageLoaded

			fileStream.on 'error', (error) ->
				console.error error
				bootbox.alert(
					title: 'Import failed'
					message: 'Your file contains errors that we could not fix.'
				)

			modelBuilder = new meshlib.ModelBuilder()

			modelBuilder.on 'model', (model) ->
				model
				.setFileName files[0].name
				.buildFaceVertexMesh()
				.done (modelPromise) -> modelPromise
				.then ->
					return modelCache
					.store model
				.then (hash) ->
					return bundles[0].modelLoader.loadByHash hash
				.then callback

			fileStream
			.pipe stlParser()
			.pipe modelBuilder

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel').toggleClass 'disabled', !enabled

	_initFileLoadHandler: =>
		fileDropper.init (event) =>
			@readFile event, [@workflowUi.bundle],
				@workflowUi.hideMenuIfPossible

		document
		.getElementById 'fileInput'
		.addEventListener 'change', (event) =>
			@readFile event, [@workflowUi.bundle],
				@workflowUi.hideMenuIfPossible


	_checkReplaceModel: =>
		question = 'You already have a model in your scene.
				 Loading the new model will replace the existing model!'

		@workflowUi.bundle.sceneManager.scene.then (scene) ->
			return true if scene.nodes.length is 0
			return new Promise (resolve) -> bootbox.confirm question, resolve

module.exports = LoadUi
