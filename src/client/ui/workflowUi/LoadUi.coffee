ReadableFileStream = require('filestream').read
meshlib = require 'meshlib'
stlParser = require 'stl-parser'

fileDropper = require '../../modelLoading/fileDropper'
modelCache = require '../../modelLoading/modelCache'
readFiles = require '../../modelLoading/readFiles'


class LoadUi
	constructor: (@workflowUi) ->
		@$panel = $ '#loadGroup'
		@_initFileLoadHandler()

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel').toggleClass 'disabled', !enabled

	_initFileLoadHandler: =>
		fileDropper.init (event) =>

			event.preventDefault()
			event.stopPropagation()

			files = event.dataTransfer.files

			@_checkReplaceModel()
			.then (loadConfirmed) =>
				return unless loadConfirmed
				readFiles files, @workflowUi.bundle,
					@workflowUi.hideMenuIfPossible

		document
		.getElementById 'fileInput'
		.addEventListener 'change', (event) =>

			event.preventDefault()
			event.stopPropagation()

			files = event.target.files

			@_checkReplaceModel()
			.then (loadConfirmed) =>
				return unless loadConfirmed
				readFiles files, @workflowUi.bundle,
					@workflowUi.hideMenuIfPossible


	_checkReplaceModel: =>
		question = 'You already have a model in your scene.
				 Loading the new model will replace the existing model!'

		return @workflowUi
		.bundle
		.sceneManager
		.scene
		.then (scene) ->
			if scene.nodes.length is 0
				return Promise.resolve true
			else
				return new Promise (resolve) ->
					bootbox.confirm question, resolve

module.exports = LoadUi
