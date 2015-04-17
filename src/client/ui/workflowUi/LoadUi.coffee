ReadableFileStream = require('filestream').read
meshlib = require 'meshlib'
stlParser = require 'stl-parser'

fileDropper = require '../../modelLoading/fileDropper'
modelCache = require '../../modelLoading/modelCache'
readFile = require '../../modelLoading/readFile'


class LoadUi
	constructor: (@workflowUi) ->
		@$panel = $ '#loadGroup'
		@_initFileLoadHandler()

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel').toggleClass 'disabled', !enabled

	_initFileLoadHandler: =>
		fileDropper.init (event) =>
			@_checkReplaceModel()
			.then (loadConfirmed) =>
				return unless loadConfirmed
				readFile event, [@workflowUi.bundle],
					@workflowUi.hideMenuIfPossible

		document
		.getElementById 'fileInput'
		.addEventListener 'change', (event) =>
			@_checkReplaceModel()
			.then (loadConfirmed) =>
				return unless loadConfirmed
				readFile event, [@workflowUi.bundle],
					@workflowUi.hideMenuIfPossible


	_checkReplaceModel: =>
		question = 'You already have a model in your scene.
				 Loading the new model will replace the existing model!'

		@workflowUi.bundle.sceneManager.scene.then (scene) ->
			return true if scene.nodes.length is 0
			return new Promise (resolve) -> bootbox.confirm question, resolve

module.exports = LoadUi
