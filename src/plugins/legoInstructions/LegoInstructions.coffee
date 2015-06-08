PNG = require('node-png').PNG
THREE = require 'three'
log = require 'loglevel'
threeHelper = require '../../client/threeHelper'

instructionsResolution = 1024

class LegoInstructions
	init: (bundle) ->
		@renderer = bundle.renderer
		@nodeVisualizer = bundle.getPlugin 'nodeVisualizer'
		@newBrickator = bundle.getPlugin 'newBrickator'
	onNodeSelect: (@selectedNode) => return

	onNodeDeselect: => @selectedNode = null

	getDownload: (selectedNode, downloadOptions) =>
		return null if downloadOptions.fileType != 'pdf'

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

					# scad generation
					promiseChain = promiseChain.then =>
						@newBrickator._getCachedData(selectedNode). then (data) =>
							console.log data
							resultingFiles.push @_createScad data.grid.getAllBricks()

					# save download
					promiseChain = promiseChain.then =>
						log.debug 'Finished pdf instructions screenshots'

						resultingFiles.push({
							fileName: 'LEGO Assembly instructions.html'
							data: @_createHtml numLayers, imageWidth
						})

						resolve resultingFiles

					# reset display mode
					promiseChain.then =>
						@nodeVisualizer.setDisplayMode @selectedNode, oldVisualizationMode

	_createScreenshotOfLayer: (promiseChain, layer, cam) =>
		return promiseChain.then =>
			return @nodeVisualizer.showBuildLayer(@selectedNode, layer)
			.then =>
				log.debug 'create screenshot of layer',layer
				@renderer.renderToImage(cam, instructionsResolution)
				.then (pixelData) =>
					pixelData.pixels = @_flipAndFitImage pixelData
					@_convertToPng(pixelData)
					.then (pngData) ->
						return ({
							fileName: "LEGO assembly instructions #{layer}.png"
							data: pngData.buffer
							imageWidth: pixelData.viewWidth
						})

	_convertToPng: (renderedImage) ->
		return new Promise (resolve, reject) ->
			png = new PNG({
				width: renderedImage.viewWidth, height: renderedImage.viewHeight
			})
			for i in [0...renderedImage.pixels.length]
				png.data[i] = renderedImage.pixels[i]
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

	_createHtml: (numLayers, imgWidth) ->
		style = "<style>
		img{width: #{imgWidth}px; max-width: 100%;}
		h1,h3{font-family:Helvetica, Arial, sans-serif;}
		</style>"

		html = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
		"http://www.w3.org/TR/html4/strict.dtd">'
		html += '<html><head>
		<title>LEGO assembly instructions</title>
		</head><body><h1>Build instructions</h1>'
		html += style

		for i in [1..numLayers]
			html += '<br>'
			html += '<h3> Layer ' + i + '</h3>'
			html += '<p><img src="LEGO%20assembly%20instructions%20' + i + '.png"></p>'

		html += '</body></html>'
		return html

	_createScad: (bricks) =>
		scad = @_scadDisclaimer()

		bricks.forEach (brick) =>
			pos = "[#{brick.getPosition().x},#{brick.getPosition().y},#{brick.getPosition().z}]"
			size = "[#{brick.getSize().x},#{brick.getSize().y},#{brick.getSize().z}]"
			scad += "GridTranslate(#{pos}){ Brick(#{size}); }\n"

		scad += '\n\n'
		scad += @_scadBase()

		return {
			fileName: 'bricks.scad'
			data: scad
		}

	_scadDisclaimer: () ->
		return '
			/*\n
			 * \n
			 * Brick layout for openSCAD\n
			 * Generated with http://brickify.it\n
			 *\n
			 */\n\n
		'
	_scadBase: () ->
		return '
			gridSpacing = [8, 8, 3.2];
			brickSpacing = [0.2, 0.2, 0.2];
			studRadius = 2.4;
			holeRadius = 2.6;
			studHeight = 1.8;

			module GridTranslate(position){
			    translate([
			        position[0] * gridSpacing[0] + brickSpacing[0]/2,
			        position[1] * gridSpacing[1] + brickSpacing[1]/2,
			        position[2] * gridSpacing[2]
			    ]){
			        children();
			    }
			}

			module Brick(size){
			    difference(){
			        union(){
			            cube([
			            size[0] * gridSpacing[0] - brickSpacing[0],
			            size[1] * gridSpacing[1] - brickSpacing[1],
			            size[2] * gridSpacing[2] - brickSpacing[2]], false);
			            
			            for ( sx = [1 : size[0]]){
			                for ( sy = [1 : size[1]]){
			                    tx = sx * gridSpacing[0] - gridSpacing[0]/2 - brickSpacing[0]/2;
			                    ty = sy * gridSpacing[1] - gridSpacing[1]/2 - brickSpacing[1]/2;
			                    tz = size[2] * gridSpacing[2] - brickSpacing[2];
			                    translate([tx, ty, tz]){
			                        cylinder(r = studRadius, h = studHeight, $fs = 0.5);
			                    }
			                }
			            }
			        }
			        union(){
			            for ( sx = [1 : size[0]]){
			                for ( sy = [1 : size[1]]){
			                    tx = sx * gridSpacing[0] - gridSpacing[0]/2 - brickSpacing[0]/2;
			                    ty = sy * gridSpacing[1] - gridSpacing[1]/2 - brickSpacing[1]/2;
			                    tz = 0;
			                    translate([tx, ty, tz - brickSpacing.z]){
			                        cylinder(r = holeRadius, h = 2 + brickSpacing.z, $fs = 0.5);
			                    }
			                }
			            }
			        }
			    }
			}
		'

module.exports = LegoInstructions
