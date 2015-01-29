Stl = require './Stl'
stlExport = require './stlExport'
optimizeModel = require './optimizeModel'

importFileBuffer = ''
meshlib = {}
meshData = {}
model = {}


toArrayBuffer = (buffer) ->

	if Buffer && Buffer.isBuffer buffer
		tempArrayBuffer = new ArrayBuffer buffer.length
		view = new Uint8Array tempArrayBuffer

		for i in [0...buffer.length]
			view[i] = buffer[i]

		return tempArrayBuffer

	else
		return buffer


meshlib.meshData = () ->
	return meshData

meshlib.model = (newModel) ->
	model = newModel

meshlib.optimize = () ->
	# TODO: fix
	model = optimizeModel model

meshlib.export = (options, callback) ->

	options ?= {}
	options.format ?= 'stl'
	options.encoding ?= 'binary'

	if options.format is 'stl'
		try
			stl = new Stl toArrayBuffer importFileBuffer
			if options.encoding is 'ascii'
				stlFile = stlExport.toAsciiStl stl.model()
			else
				stlFile = stlExport.toBinaryStl stl.model()
		catch error
			return callback error

		callback(null, stlFile)
	else
		throw new Error options.format + ' is no supported file format!'

	return meshlib


meshlib.parse = (fileBuffer, options, callback) ->

	if not fileBuffer
		throw new Error 'STL buffer is empty'
	else
		importFileBuffer = fileBuffer

	options ?= {}
	options.format ?= 'stl'

	if options.format is 'stl'
		try
			stl = new Stl toArrayBuffer fileBuffer
			model = stl.model()
		catch error
			if typeof callback is 'function'
				callback error
				return meshlib
			else
				throw error

	if typeof callback is 'function'
		callback(null, model)

	return meshlib


module.exports = meshlib
