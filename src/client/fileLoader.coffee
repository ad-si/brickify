pluginHooks = require '../common/pluginHooks'

fileReader = new FileReader()

fileNameCache = []

handleDroppedFile = (event) ->
	fileContent = event.target.result

	# assume files are loaded in the same order as they are provided in the
	# 'files' array in readFiles.
	# TODO: think of a better way to match file content and file name
	fileName = fileNameCache.shift()

	loaders = pluginHooks.get 'importFile'
	# TODO: Add success/fail handling
	loader fileName, fileContent for loader in loaders

module.exports.init = () ->
	fileReader.addEventListener(
		'loadend',
		handleDroppedFile.bind(@),
		false
	)

module.exports.readFiles = (files) ->
	for file in files
		# TODO: remove extension check
		if file.name.toLowerCase().search( '.stl' ) >= 0
			fileNameCache.push file.name
			fileReader.readAsBinaryString( file )
