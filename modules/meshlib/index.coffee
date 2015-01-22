jbinary = require 'jbinary'
Stl = require './Stl'

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

meshlib.model = () ->
	return model

meshlib.parse = (fileBuffer, options, callback) ->

	if not fileBuffer
		throw new Error 'STL buffer is empty'

	options ?= {}
	options.format ?= 'stl'

	if options.format is 'stl'
		try
			stl = new Stl toArrayBuffer fileBuffer
			model = stl.model()
		catch error
			return callback error

	callback(null, model)


module.exports = meshlib
