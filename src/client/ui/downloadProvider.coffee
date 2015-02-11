$ = require 'jquery'
modelCache = require '../modelCache'
saveAs = require 'filesaver.js'

module.exports = class DownloadProvider
	constructor: (@bundle) ->
		return

	init: (jqueryString, @sceneManager) =>
		@jqueryObject = $(jqueryString)

		@jqueryObject.on 'click', () =>
			selNode = @sceneManager.selectedNode
			if selNode?
				@_createDownload selNode


	_createDownload: (selectedNode) =>
		console.log 'Creating Download...'
		
		promisesArray = @bundle.pluginHooks.getDownload selectedNode

		Promise.all(promisesArray).then (resultsArray) =>
			for r in resultsArray
				saveAs r.data, r.fileName

