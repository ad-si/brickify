modelCache = require './modelCache'

module.exports = class DownloadProvider
	constructor: (@bundle) ->
		return

	createDownload: (selectedNode) =>
		console.log 'Creating Download...'
		# first, subtract every custom geometry from original model (CSG)
		returnArrays = @bundle.pluginHooks.getSubtractiveCsg @selectedNode
