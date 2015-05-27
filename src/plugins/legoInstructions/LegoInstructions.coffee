PNG = require('node-png').PNG
streamToArray = require 'stream-to-array'

class LegoInstructions
	init: (bundle) ->
		@renderer = bundle.renderer

	getDownload: (downloadOptions, selectedNode) =>
		return new Promise (resolve, reject) =>
			@renderer.renderToImage()
			.then (pixelData) =>
				@_convertToPng(pixelData)
				.then (pngData) =>
					resolve({
						fileName: 'LEGO assembly instructions.png'
						data: pngData.buffer
					})

	_convertToPng: (renderedImage) ->
		return new Promise (resolve, reject) ->
			png = new PNG({width: renderedImage.imageWidth, height: renderedImage.imageHeight})
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

module.exports = LegoInstructions