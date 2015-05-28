$ = require 'jquery'
modelCache = require '../../modelLoading/modelCache'
saveAs = require 'filesaver.js'
JSZip = require 'jszip'
log = require 'loglevel'


module.exports = class DownloadProvider
	constructor: (@bundle) ->
		return

	init: (stlButtonId, pdfButtonId, @exportUi, @sceneManager) =>
		@stljQueryObject = $(stlButtonId)
		@stljQueryObject.on 'click', =>
			selNode = @sceneManager.selectedNode
			if selNode?
				@_createDownload 'stl', selNode

		@pdfjQueryObject = $(pdfButtonId)
		@pdfjQueryObject.on 'click', =>
			selNode = @sceneManager.selectedNode
			if selNode?
				@_createDownload 'pdf', selNode

	_createDownload: (fileType, selectedNode) =>
		downloadOptions = {
			fileType: fileType
			studRadius: @exportUi.studRadius
			holeRadius: @exportUi.holeRadius
		}

		promisesArray = @bundle.pluginHooks.getDownload selectedNode, downloadOptions

		Promise.all(promisesArray).then (resultsArray) =>
			files = @_collectFiles resultsArray

			if files.length is 0
				bootbox.alert(
					title: 'There is nothing to download at the moment'
					message: 'This happens when your whole model is made out of LEGO
										and you have not selected anything	to be 3D-printed. Use
										the Make 3D-print brush for that'
				)
			if files.length is 1
				data = files[0].data
				fileName = files[0].fileName
				saveAs data, fileName
			if files.length > 1
				promisesArray = []
				for file in files
					fileConversion = @_convertToArrayBuffer file.data, file.fileName
					promisesArray.push fileConversion if fileConversion?

				Promise.all(promisesArray).then (resultsArray) ->
					zip = new JSZip()
					options = binary: true
					for result in resultsArray
						zip.file result.fileName, result.data, options
					zipFile = zip.generate type: 'blob'
					saveAs zipFile, "brickify-#{selectedNode.name}-#{fileType}.zip"

	_collectFiles: (array) ->
		files = []
		for entry in array
			continue if not entry?
			if Array.isArray entry
				for subEntry in entry
					if subEntry.fileName.length > 0
						files.push data: subEntry.data, fileName: subEntry.fileName
			else if entry.fileName.length > 0
				files.push data: entry.data, fileName: entry.fileName
		return files

	_convertToArrayBuffer: (data, fileName) =>
		if data instanceof Blob
			return @_arrayBufferFromBlob data, fileName
		if data instanceof ArrayBuffer
			return Promise.resolve {data: data, fileName: fileName}
		if (data instanceof String) or (typeof(data) == 'string')
			return @_arrayBufferFromString data, fileName

		log.warn 'No conversion method found for file',fileName
		return null


	_arrayBufferFromBlob: (blob, fileName) ->
		reader = new FileReader()
		return new Promise (resolve, reject) ->
			reader.onload = ->
				resolve {data: reader.result, fileName: fileName}
			reader.onerror = reject
			reader.onabort = reject
			reader.readAsArrayBuffer blob

	_arrayBufferFromString: (string, fileName) ->
		return new Promise (resolve, reject) ->
			buffer = new ArrayBuffer(string.length * 2)
			bufferView = new Uint16Array(buffer)
			for i in [0...string.length] by 1
				bufferView[i] = string.charCodeAt i

			resolve {data: buffer, fileName: fileName}

