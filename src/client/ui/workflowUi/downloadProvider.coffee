$ = require 'jquery'
modelCache = require '../../modelLoading/modelCache'
saveAs = require 'filesaver.js'

module.exports = class DownloadProvider
	constructor: (@bundle) ->
		return

	init: (jqueryString, @exportUi, @sceneManager) =>
		@jqueryObject = $(jqueryString)

		@jqueryObject.on 'click', =>
			selNode = @sceneManager.selectedNode
			if selNode?
				@_createDownload 'stl', selNode

	_createDownload: (fileType, selectedNode) =>
		downloadOptions = {
			fileType: fileType
			studRadius: @exportUi.studRadius
		}

		promisesArray = @bundle.pluginHooks.getDownload selectedNode, downloadOptions

		Promise.all(promisesArray).then (resultsArray) ->
			saveAs result.data, result.fileName for result in resultsArray
