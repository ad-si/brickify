stlLoader = require './stlLoader'
OptimizedModel = require '../../../common/OptimizedModel'

module.exports = class StlImport
	constructor: () ->
		@threejsRootNode = null
		@globalConfigInstance = null

	init: (globalConfig) ->
		@globalConfigInstance = globalConfig

	# Imports the stl, optimizes it,
	# sends it to the server (if not cached there)
	# and adds it to the scene as a THREE.Geometry
	importFile: (fileName, fileContent) ->
		errorCallback = (errors) ->
			console.error 'Errors occured while importing the stl file:'
			console.error '-> ' + error for error in errors
		optimizedModel = stlLoader.parse fileContent, errorCallback, true, true

		# happens with empty files
		if !optimizedModel
			return

		optimizedModel.originalFileName = fileName
		return optimizedModel
