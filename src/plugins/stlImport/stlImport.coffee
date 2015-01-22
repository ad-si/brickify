meshlib = require '../../../modules/meshlib'

module.exports = class StlImport

	# Imports the stl, optimizes it,
	# sends it to the server (if not cached there)
	# and adds it to the scene as a THREE.Geometry
	importFile: (fileName, fileBuffer, callback) ->

		meshlib.parse fileBuffer, null, (error, model) ->
			if error or not model
				callback error
			else
				model.originalFileName = fileName
				callback null, model
