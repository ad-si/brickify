modelCache = require './modelCache'

module.exports = class DownloadProvider
	constructor: (@bundle) ->
		return

	createDownload: (selectedNode) =>
		console.log 'Creating Download...'
		
		returnArrays = @bundle.pluginHooks.getStlDownload selectedNode
