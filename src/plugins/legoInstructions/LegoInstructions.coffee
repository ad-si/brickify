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

	onNodeSelect: (@selectedNode) => return

	onNodeDeselect: => @selectedNode = null

	getDownload: (selectedNode, downloadOptions) =>
		return null if downloadOptions.type != 'instructions'

		return new Promise (resolve, reject) =>
			log.debug 'Creating pdf instructions...'

			# pseudoisometric
			cam = new THREE.PerspectiveCamera(
				@renderer.camera.fov, @renderer.camera.aspect, 1, 1000
			)

			cam.position.set(1, 1, 1)
			cam.lookAt(new THREE.Vector3(0, 0, 0))
			cam.up = new THREE.Vector3(0, 0, 1)

			@nodeVisualizer.getBrickThreeNode selectedNode
			.then (brickNode) =>
				boundingSphere = threeHelper.getBoundingSphere brickNode
				threeHelper.zoomToBoundingSphere(
					cam
					@renderer.scene
					null
					boundingSphere
				)
			.then =>
				# disable pipeline
				@fidelityControl.enableScreenshotMode()

				# enter build mode
				oldVisualizationMode = @nodeVisualizer.getDisplayMode()
				@nodeVisualizer.setDisplayMode(@selectedNode, 'build')
				.then (numLayers) =>
					resultingFiles = []

					# screenshot of each layer
					promiseChain = Promise.resolve()
					imageWidth = 0
					for layer in [1..numLayers]
						promiseChain = @_createScreenshotOfLayer(promiseChain, layer, cam)
						promiseChain = promiseChain.then (fileData) ->
							resultingFiles.push {
								fileName: fileData.fileName
								data: fileData.data
							}
							imageWidth = fileData.imageWidth

					# scad and piece list generation
					pieceListHtml = ''
					promiseChain = promiseChain.then =>
						@newBrickator._getCachedData(selectedNode).then (data) ->
							pieceList = pieceListGenerator.generatePieceList data.grid.getAllBricks()
							pieceListHtml = pieceListGenerator.getHtml pieceList

							resultingFiles.push openScadGenerator.generateScad(
								data.grid.getAllBricks()
							)

					# save download
					promiseChain = promiseChain.then =>
						log.debug 'Finished pdf instructions screenshots'

						# add instructions html to download
						resultingFiles.push({
							fileName: 'LEGO Assembly instructions.html'
							data: @_createHtml numLayers, imageWidth, pieceListHtml
						})

						resolve resultingFiles

					# reset display mode
					promiseChain.then =>
						@nodeVisualizer.setDisplayMode @selectedNode, oldVisualizationMode
						@fidelityControl.disableScreenshotMode()

	_createScreenshotOfLayer: (promiseChain, layer, cam) =>
		return promiseChain.then =>
			return @nodeVisualizer.showBuildLayer(@selectedNode, layer)
			.then =>
				log.debug 'create screenshot of layer',layer
				@renderer.renderToImage(cam, @imageResolution)
				.then (pixelData) =>
					flippedImage = @_flipAndFitImage pixelData
					@_convertToPng(flippedImage)
					.then (pngData) ->
						return ({
							fileName: "LEGO assembly instructions #{layer}.png"
							data: pngData.buffer
							imageWidth: flippedImage.width
						})

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

	# flips the image horizontally (because renderer delivers it upside down)
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

	_setPixel: (imageData, imageWidth, x, y, rgbaArray) ->
		index = (imageWidth * y) + x
		index *= 4
		imageData[index] = rgbaArray[0]
		imageData[index + 1] = rgbaArray[1]
		imageData[index + 2] = rgbaArray[2]
		imageData[index + 3] = rgbaArray[3]

	_createHtml: (numLayers, imgWidth, pieceListHtml = null) ->
		style = "<style>
		img{width: #{imgWidth}px; max-width: 100%;}
		h1,h3,p,td{font-family:Helvetica, Arial, sans-serif;}
		td{min-width: 80px;}
		.pageBreak{page-break-before: always;}
		</style>"

		html = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
		"http://www.w3.org/TR/html4/strict.dtd">'
		html += '<html><head>
		<title>LEGO assembly instructions</title>
		</head><body><h1>Build instructions</h1>'
		html += style

		html += pieceListHtml if pieceListHtml?

		for i in [1..numLayers]
			html += '<br>'
			html += '<h3 class="pageBreak"> Layer ' + i + '</h3>'
			html += '<p><img src="LEGO%20assembly%20instructions%20' + i + '.png"></p>'

		html += '</body></html>'
		return html

module.exports = LegoInstructions
