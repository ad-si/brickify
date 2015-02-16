modelCache = require './modelCache'
saveAs = require 'filesaver.js'

module.exports = class DownloadProvider
	constructor: (@bundle) ->
		return

	createDownload: (selectedNode) =>
		console.log 'Creating Download...'
		
		promisesArray = @bundle.pluginHooks.getDownload selectedNode

		Promise.all(promisesArray).then (resultsArray) =>
			for r in resultsArray
				saveAs r.data, r.fileName

