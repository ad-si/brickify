meshlib = require 'meshlib'

module.exports = class StlImport

	# Imports the stl, optimizes it
	importFile: (fileName, fileBuffer, callback) ->

		meshlib.parse fileBuffer, null, (error, model) ->
			if error or not model
				callback error
			else
				model.originalFileName = fileName
				callback null, model
