PNG = require('node-png').PNG
streamToArray = require 'stream-to-array'

class LegoInstructions
	init: (bundle) ->
		@renderer = bundle.renderer

	getDownload: (downloadOptions, selectedNode) =>
		return new Promise (resolve, reject) =>
			@renderer.renderToImage()
			.then (pixelData) =>
				pixelData.pixels = @_flipAndFitImage pixelData
				@_convertToPng(pixelData)
				.then (pngData) =>
					resolve({
						fileName: 'LEGO assembly instructions.png'
						data: pngData.buffer
					})

	_convertToPng: (renderedImage) ->
		return new Promise (resolve, reject) ->
			png = new PNG({width: renderedImage.viewWidth, height: renderedImage.viewHeight})
			for i in [0...renderedImage.pixels.length]
				png.data[i] = renderedImage.pixels[i]
			png.pack()

			pngData = new Uint8Array(0)

			# read png stream
			png.on 'data', (data) ->
				newData = new Uint8Array(pngData.length + data.length)
				for i in [0...pngData.length]
					newData[i] = pngData[i]
				for i in [0...data.length]
					newData[pngData.length + i] = data[i]
				pngData = newData
			png.on 'end', ->
				resolve pngData

	# flips the image horizontally (because renderer delivers it upside down)
	# and scales it to actual recorded screen measurements (because it is always
	# in size 2^n)
	_flipAndFitImage: (renderedImage) ->
		sw = renderedImage.viewWidth
		sh = renderedImage.viewHeight
		iw = renderedImage.imageWidth
		ih = renderedImage.imageHeight

		newImage = new Uint8Array(sw * sh * 4)

		scaleX = iw / sw
		scaleY = ih / sh

		maxX = sw - 1
		maxY = sh - 1

		for y in [0..maxY]
			# flip new y coordinates
			newY = maxY - y
			oldY = Math.round(y * scaleY)

			for x in [0..maxX]
				newCoords =  (newY * sw) + x
				newCoords *= 4
				oldCoords =  (oldY * iw) + Math.round(x * scaleX)
				oldCoords *= 4
				
				newImage[newCoords] = renderedImage.pixels[oldCoords]
				newImage[newCoords + 1] = renderedImage.pixels[oldCoords + 1]
				newImage[newCoords + 2] = renderedImage.pixels[oldCoords + 2]
				newImage[newCoords + 3] = renderedImage.pixels[oldCoords + 3]

		return newImage
module.exports = LegoInstructions