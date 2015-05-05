$ = require 'jquery'
modelCache = require '../../modelLoading/modelCache'
saveAs = require 'filesaver.js'
log = require 'loglevel'


module.exports = class DownloadProvider
	constructor: ({@bundle, selectorString, @exportUi, @sceneManager}) ->
		$(selectorString).on 'click', =>
			selNode = @sceneManager.selectedNode
			if selNode?
				@_createDownload 'stl', selNode

	_createDownload: (fileType, selectedNode) =>
		downloadOptions = {
			fileType: fileType
			studRadius: @exportUi.studRadius
			holeRadius: @exportUi.holeRadius
		}

		downloadPromises = @bundle.pluginHooks.getDownload(
			selectedNode,
			downloadOptions
		)

		Promise
		.all downloadPromises
		.then (resultsArray) ->
			for result in resultsArray
				saveAs new Blob([result.data]), result.fileName
		.catch (error) ->
			log.error error
