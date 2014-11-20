pluginHooks = require '../common/pluginHooks'

fileReader = new FileReader()

handleDroppedFile = (event) ->
	fileContent = event.target.result
	loaders = pluginHooks.get 'importFile'
	# TODO: Add success/fail handling
	loader fileContent for loader in loaders

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
			fileReader.readAsBinaryString( file )
