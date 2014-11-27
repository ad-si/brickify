###
# @module fileLoader
###

pluginHooks = require '../common/pluginHooks'

module.exports.readFiles = (files) ->
		readFile file for file in files

readFile = (file) ->
	reader = new FileReader()
	# TODO: remove extension check
	if file.name.toLowerCase().search '.stl' >= 0
		reader.onload = loadFile file.name
		reader.readAsBinaryString file

loadFile = (filename) -> (event) ->
	fileContent = event.target.result

	for loader in pluginHooks.get 'importFile'
		optimizedModel = loader filename, fileContent
		return if optimizedModel?
