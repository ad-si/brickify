droptext = null
uploadString = 'Uploading file
<img src="img/spinner.gif" style="height: 1.2em;">'

module.exports.init = (targetDomObject, text) ->
	bindDropHandler targetDomObject
	droptext = text

bindDropHandler = (target) ->
	target.addEventListener 'drop', onModelDrop, false
	target.addEventListener 'dragover', ignoreEvent, false
	target.addEventListener 'dragleave', ignoreEvent, false

ignoreEvent = (event) ->
	event.preventDefault()
	event.stopPropagation()

onModelDrop = (event) ->
	event.preventDefault()
	event.stopPropagation()

	files = event.target.files ? event.dataTransfer.files
	if files?
		file = files[0]

		fn = file.name.toLowerCase()
		if (fn.search('.stl') == fn.length - 4)
			droptext.html uploadString
			loadFile file
		else
			alert 'Only .stl files are supported at the moment'

loadFile = (file) ->
	reader = new FileReader()
	reader.onLoad = handleLoadedFile
	reader.readAsBinaryString(file)


handleLoadedFile = (content) ->
	console.log 'File loaded!'
	return