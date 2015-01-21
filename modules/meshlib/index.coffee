Stl = require './Stl'

meshlib = {}
meshData = {}
model = {}


meshlib.meshData = () ->
	return meshData

meshlib.model = () ->
	return model

meshlib.parse = (fileContentString, options, callback) ->

	options ?= {}

	options.encoding ?= 'utf-8'
	options.format ?= 'stl'

	if options.format is 'stl'
		try
			stl = new Stl(fileContentString)
			model = stl.model()
		catch error
			return callback error

	callback(null, model)


module.exports = meshlib
