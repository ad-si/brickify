$ = require 'jquery'
modelCache = require '../../modelLoading/modelCache'
saveAs = require 'filesaver.js'


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

		promisesArray = @bundle.pluginHooks.getDownload selectedNode, downloadOptions

		Promise.all(promisesArray).then (resultsArray) ->
			for result in resultsArray
				if result.fileName.length > 0
					saveAs result.data, result.fileName
