PNG = require('node-png').PNG
THREE = require 'three'
log = require 'loglevel'
threeHelper = require '../../client/threeHelper'
pieceListGenerator = require './PieceListGenerator'
openScadGenerator = require './OpenScadGenerator'

class LegoInstructions
	init: (bundle) ->
		@renderer = bundle.renderer
		@nodeVisualizer = bundle.getPlugin 'nodeVisualizer'
		@newBrickator = bundle.getPlugin 'newBrickator'
		@fidelityControl = bundle.getPlugin 'fidelity-control'
		@imageResolution = bundle.globalConfig.legoInstructionResolution

	getDownload: (node, downloadOptions) =>
		return null if downloadOptions.type != 'instructions'

		log.debug 'Creating instructions...'

		# pseudoisometric
		camera = new THREE.PerspectiveCamera(
			@renderer.camera.fov, @renderer.camera.aspect, 1, 1000
		)

		camera.position.set(1, 1, 1)
		camera.lookAt new THREE.Vector3(0, 0, 0)
		camera.up = new THREE.Vector3(0, 0, 1)

		oldVisualizationMode = @nodeVisualizer.getDisplayMode()

		@nodeVisualizer.getBrickThreeNode node
		.then (brickNode) =>
			threeHelper.zoomToBoundingSphere(
				camera
				@renderer.scene
				null
				threeHelper.getBoundingSphere brickNode
			)
			# disable pipeline and fidelity changes
			@fidelityControl.enableScreenshotMode()
			# enter build mode
			@nodeVisualizer.setDisplayMode node, 'build'
		.then => @newBrickator.getNodeData node
		.then (data) =>
			{min: minLayer, max: maxLayer} = data.grid.getLegoVoxelsZRange()
			numLayers = maxLayer - minLayer + 1
			# If there is 3D print below first lego layer, show lego starting
			# with layer 1 and show only 3D print in first instruction layer
			numLayers += 1 if minLayer > 0

			# scad and piece list generation
			bricks = data.grid.getAllBricks()

			files = []
			files.push openScadGenerator.generateScad bricks

			# add instructions html to download
			pieceList = pieceListGenerator.generatePieceList bricks
			files.push @_createHtml numLayers, pieceList

			# Create temporary data object, because we need more than
			# Files
			dataObject = {files: files, pieceList: pieceList}

			# Take screenshots and convert them to png
			@_takeScreenshots node, numLayers, camera
			.then (images) =>
				dataObject.files.push images...
				log.debug 'Finished instruction screenshots'

				# save download
				return dataObject
		.then (dataObject) =>
			# Load and save piece images
			@_downloadPieceListImages dataObject.pieceList
			.then (imageFiles) ->
				dataObject.files.push imageFiles...
				return dataObject.files
		.then (files) =>
			# reset display mode
			@nodeVisualizer.setDisplayMode node, oldVisualizationMode
			@fidelityControl.disableScreenshotMode()

			return files
		.catch (error) -> log.error error

	showPartListPopup: (node) =>
		@newBrickator.getNodeData node
		.then (data) =>
			bricks = data.grid.getAllBricks()
			pieceList = pieceListGenerator.generatePieceList bricks
			pieceListHtml = pieceListGenerator.getHtml pieceList, false

			bootbox.dialog
				title: 'Parts needed'
				message: pieceListHtml
				backdrop: true

	_takeScreenshots: (node, numLayers, camera) =>
		files = []
		takeScreenshot = (layer) => =>
			@_createScreenshotOfLayer node, layer, camera
			.then (fileData) ->
				files.push {
					fileName: fileData.fileName
					data: fileData.data
				}

		# screenshot of each layer
		promiseChain = Promise.resolve()
		for layer in [1..numLayers]
			promiseChain = promiseChain.then takeScreenshot layer

		return promiseChain.then -> files

	_createScreenshotOfLayer: (node, layer, camera) =>
		return @nodeVisualizer.showBuildLayer node, layer
		.then =>
			log.debug 'Create screenshot of layer', layer
			return @renderer.renderToImage camera, @imageResolution
		.then (pixelData) =>
			flippedImage = @_flipAndFitImage pixelData
			return @_convertToPng(flippedImage)
			.then (pngData) ->
				return (
					fileName: "LEGO assembly instructions #{layer}.png"
					data: pngData.buffer
					imageWidth: flippedImage.width
				)

	_convertToPng: (image) ->
		return new Promise (resolve, reject) ->
			png = new PNG({
				width: image.width
				height: image.height
			})
			for i in [0...image.data.length]
				png.data[i] = image.data[i]
			png.pack()

			pngData = new Uint8Array(0)

			# read png stream
			png.on 'data', (data) ->
				newData = new Uint8Array(pngData.length + data.length)
				newData.set pngData
				newData.set data, pngData.length
				pngData = newData
			png.on 'end', ->
				resolve pngData

	# flips the image vertically (because renderer delivers it upside down)
	# and scales it to actual recorded screen measurements (because it is always
	# in size 2^n)
	_flipAndFitImage: (renderedImage) =>
		sw = renderedImage.viewWidth
		sh = renderedImage.viewHeight
		iw = renderedImage.imageWidth
		ih = renderedImage.imageHeight

		# scale screen to match image dimensions,
		# but retain aspect ratio
		biggerView = Math.max sw, sh
		biggerImage = Math.max iw, ih

		scaleFactor = biggerImage / biggerView

		sw = Math.round sw * scaleFactor
		sh = Math.round sh * scaleFactor

		# create new image
		newImage = new Uint8Array(sw * sh * 4)

		scaleX = iw / sw
		scaleY = ih / sh

		for y in [0...sh]
			# flip new y coordinates
			newY = (sh - 1) - y
			oldY = Math.round y * scaleY

			for x in [0...sw]
				newX = x
				oldX = Math.round x * scaleX

				pixelData = @_getPixel renderedImage.pixels, iw, oldX, oldY
				@_setPixel newImage, sw, newX, newY, pixelData

		return {
			data: newImage
			width: sw
			height: sh
		}

	_getPixel: (imageData, imageWidth, x, y) ->
		index = (imageWidth * y) + x
		index *= 4
		return [
			imageData[index]
			imageData[index + 1]
			imageData[index + 2]
			imageData[index + 3]
		]

	_setPixel: (imageData, imageWidth, x, y, [r, g, b, a]) ->
		index = (imageWidth * y) + x
		index *= 4
		imageData[index] = r
		imageData[index + 1] = g
		imageData[index + 2] = b
		imageData[index + 3] = a

	_createHtml: (numLayers, pieceList) =>
		pieceListHtml = pieceListGenerator.getHtml pieceList

		style = '<style>
		img{max-width: 100%;}
		h1,h3,p,td{font-family:Helvetica, Arial, sans-serif;}
		td{min-width: 80px;}
		.pageBreak{page-break-before: always;}
		</style>'

		html = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
		"http://www.w3.org/TR/html4/strict.dtd">'
		html += '<html><head>
		<title>LEGO assembly instructions</title>
		</head><body><h1>Build instructions</h1>'

		html += style

		html += pieceListHtml

		for i in [1..numLayers]
			html += '<br><br>'
			html += '<h3 class="pageBreak"> Layer ' + i + '</h3>'
			html += '<p><img src="LEGO%20assembly%20instructions%20' + i + '.png"></p>'

		html += '</body></html>'

		return {
			fileName: 'LEGO Assembly instructions.html'
			data: html
		}

	_downloadPieceListImages: (pieceList) =>
		return Promise.all pieceList.map (piece) => @_downloadPieceImage piece

	_downloadPieceImage: (piece) ->
		return new Promise (resolve, reject) ->
			xhr = new XMLHttpRequest()
			fileName = "img/partList/partList (#{piece.sizeIndex+1}).png"
			xhr.open 'GET', fileName
			xhr.responseType = 'arraybuffer'
			xhr.onload = (event) ->
				resolve {
					fileName: fileName
					# as requested, response is an ArrayBuffer
					data: @response
				}
			xhr.send()

module.exports = LegoInstructions
