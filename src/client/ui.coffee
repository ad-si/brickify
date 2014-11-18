###
# @module ui
###

statesync = require './statesync'
objectTree = require '../common/objectTree'
renderer = require './renderer'

module.exports = (globalConfig) ->
	return {
		stlLoader: new THREE.STLLoader()
		fileReader: new FileReader()

		# overwrite if in your code neccessary
		loadHandler: ( event ) ->
			return 0

		dropHandler: (event) ->
			event.stopPropagation()
			event.preventDefault()
			files = event.target.files ? event.dataTransfer.files
			for file in files
				if file.name.toLowerCase().search( '.stl' ) >= 0
					@fileReader.readAsBinaryString( file )

		dragOverHandler: (event) ->
			event.stopPropagation()
			event.preventDefault()
			event.dataTransfer.dropEffect = 'copy'

		# Bound to updates to the window size:
		# Called whenever the window is resized.
		windowResizeHandler: (event) ->
			renderer.windowResizeHandler()

		init: ->
			renderer.init(globalConfig)

			# event listener
			renderer.getDomElement().addEventListener(
				'dragover'
				@dragOverHandler.bind @
				false
			)
			renderer.getDomElement().addEventListener(
				'drop'
				@dropHandler.bind @
				false
			)
			@fileReader.addEventListener(
				'loadend',
				@loadHandler.bind @,
				false
			)
			window.addEventListener(
				'resize',
				@windowResizeHandler.bind @,
				false
			)
	}
