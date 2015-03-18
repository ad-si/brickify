meshlib = require 'meshlib'
modelCache = require '../client/modelCache'

uploadFinishedCallback = null

readingString = 'Reading file
<img src="img/spinner.gif" id="spinner">'
uploadString = 'Uploading file
<img src="img/spinner.gif" id="spinner">'
loadedString = 'File loaded!'

module.exports.onLoadFile = (event, feedbackTargets, finishedCallback) ->
	uploadFinishedCallback = finishedCallback

	event.preventDefault()
	event.stopPropagation()

	files = event.target.files ? event.dataTransfer.files
	if files?
		file = files[0]

		fn = file.name.toLowerCase()
		if (fn.search('.stl') == fn.length - 4)
			feedbackTargets.each (i, el) -> el.innerHTML = readingString
			loadFile feedbackTargets, file
		else
			bootbox.alert({
				title: 'Your file does not have the right format!'
				message: 'Only .stl files are supported at the moment. We are working on
adding more file formats'
			})

loadFile = (feedbackTargets, file) ->
	reader = new FileReader()
	reader.onload = handleLoadedFile(feedbackTargets, file.name)
	reader.readAsArrayBuffer(file)

handleLoadedFile = (feedbackTargets, filename) ->
	loadCallback = 	(event) ->
		console.log "File #{filename} loaded"
		fileContent = event.target.result
		importErrors = false

		meshlib.parse fileContent, null, (error, optimizedModel) ->
			if error?
				importErrors = true
			else
				# happens with empty files
				if !optimizedModel
					bootbox.alert({
						title: 'Import failed'
						message: 'Your file contains errors that we could not fix automatically.'
					})

				optimizedModel.originalFileName = filename

				feedbackTargets.each (i, el) -> el.innerHTML = uploadString

				ufc = (md5hash) ->
					feedbackTargets.each (i, el) -> el.innerHTML = loadedString
					if uploadFinishedCallback?
						uploadFinishedCallback(md5hash, importErrors)

				modelCache.store(optimizedModel).then(ufc)

		return

	return loadCallback
