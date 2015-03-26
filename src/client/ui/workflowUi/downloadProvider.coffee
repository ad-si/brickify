$ = require 'jquery'
modelCache = require '../../modelLoading/modelCache'
saveAs = require 'filesaver.js'

module.exports = class DownloadProvider
	constructor: (@bundle) ->
		return

	init: (jqueryString, @sceneManager) =>
		@jqueryObject = $(jqueryString)

		@jqueryObject.on 'click', =>
			selNode = @sceneManager.selectedNode
			if selNode?
				@_createDownload selNode

	_createDownload: (selectedNode) =>
		console.log 'Creating Download...'

		promisesArray = @bundle.pluginHooks.getDownload selectedNode

		Promise.all(promisesArray).then (resultsArray) ->
			saveAs result.data, result.fileName for result in resultsArray
