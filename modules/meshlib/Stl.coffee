require 'string.prototype.startswith'
require 'string.prototype.includes'

textEncoding = require 'text-encoding'

Vec3 = require './Vector'
optimizeModel = require './optimizeModel'


FileError = (message, calcDataLength, dataLength) ->
	this.name = 'FileError'
	this.message = message or "Calculated length of #{calcDataLength}
					does not match specified file-size of #{dataLength}.
					Triangles might be missing!"
FileError.prototype = new Error

FacetError = (message) ->
	this.name = 'FacetError'
	this.message = message or 'Previous facet was not completed!'
FacetError.prototype = new Error

NormalError = (message) ->
	this.name = 'NormalError'
	this.message = message or "Invalid normal definition: (#{nx}, #{ny}, #{nz})"
NormalError.prototype = new Error

VertexError = (message) ->
	this.name = 'VertexError'
	this.message = message or "Invalid vertex definition: (#{nx}, #{ny}, #{nz})"
VertexError.prototype = new Error




parseAscii = (fileContent) ->
	astl = new Ascii(fileContent)
	stl = new Binary()

	# TODO:
	# if calcDataLength > dataLength
	#   throw new FileError null, calcDataLength, dataLength

	currentPoly = null

	while !astl.reachedEnd()
		cmd = astl.nextText()
		cmd = cmd.toLowerCase()

		switch cmd
			when 'solid'
				astl.nextText() #skip description of model

			when 'facet'
				if (currentPoly?)
					throw new FacetError
					stl.addPolygon currentPoly
					currentPoly = null
				currentPoly = new Poly()

			when 'endfacet'
				if !(currentPoly?)
					throw new FacetError 'Facet was ended without beginning it!'
				else
					stl.addPolygon currentPoly
					currentPoly = null

			when 'normal'
				nx = parseFloat astl.nextText()
				ny = parseFloat astl.nextText()
				nz = parseFloat astl.nextText()

				if (!(nx?) or !(ny?) or !(nz?))
					throw new NormalError
				else
					if not (currentPoly?)
						throw new NormalError 'Normal definition
									without an existing polygon!'
						currentPoly = new Poly()
					currentPoly.setNormal new Vec3(nx, ny, nz)

			when 'vertex'
				vx = parseFloat astl.nextText()
				vy = parseFloat astl.nextText()
				vz = parseFloat astl.nextText()

				if (!(vx?) or !(vy?) or !(vz?))
					throw new VertexError

				else
					if not (currentPoly?)
						throw new VertexError 'Point definition without
											an existing polygon!'
						currentPoly = new Poly()
					currentPoly.addPoint new Vec3(vx, vy, vz)

	return stl

# Parses a binary stl file to the internal representation
parseBinary = (stlBuffer) ->

	stl = new Binary()
	reader = new DataView stlBuffer, 80
	numTriangles = reader.getUint32 0, true

	#check if file size matches with numTriangles
	dataLength = stlBuffer.byteLength - 80 - 4
	polyLength = 50
	calcDataLength = polyLength * numTriangles

	if calcDataLength > dataLength
		throw new FileError null, calcDataLength, dataLength

	binaryIndex = 4
	while (binaryIndex - 4) + polyLength <= dataLength
		poly = new Poly()
		nx = reader.getFloat32 binaryIndex, true
		binaryIndex += 4
		ny = reader.getFloat32 binaryIndex, true
		binaryIndex += 4
		nz = reader.getFloat32 binaryIndex, true
		binaryIndex += 4
		poly.setNormal new Vec3(nx, ny, nz)
		for i in [0..2]
			vx = reader.getFloat32 binaryIndex, true
			binaryIndex += 4
			vy = reader.getFloat32 binaryIndex, true
			binaryIndex += 4
			vz = reader.getFloat32 binaryIndex, true
			binaryIndex += 4
			poly.addPoint new Vec3(vx, vy, vz)
		#skip uint 16
		binaryIndex += 2
		stl.addPolygon poly

	return stl


class Ascii

	whitespaces = [' ', '\r', '\n', '\t', '\v', '\f']

	skipWhitespaces = () ->
		skip = true
		while skip
			if (@currentCharIsWhitespace() && !@reachedEnd())
				@index++
			else
				skip = false

	constructor: (fileContent) ->
		@content = fileContent
		@index = 0

	nextText: () ->
		skipWhitespaces.call(@)
		return @readUntilWhitespace()

	currentChar: () ->
		return @content[@index]

	currentCharIsWhitespace: () ->
		for space in whitespaces
			if @currentChar() == space
				return true
		return false

	readUntilWhitespace: () ->
		readContent = ''
		while (!@currentCharIsWhitespace() && !@reachedEnd())
			readContent = readContent + @currentChar()
			@index++
		return readContent

	reachedEnd: () ->
		return (@index == @content.length)


# An unoptimized data structure that holds the same content as a stl file
class Binary
	constructor: () ->
		@polygons = []
		@importErrors = []

	addPolygon: (stlPolygon) ->
		@polygons.push(stlPolygon)

	addError: (string) ->
		@importErrors.push string

	removeInvalidPolygons: (infoResult) ->
		newPolys = []
		deletedPolys = 0

		for poly in @polygons
			#check if it has 3 vectors
			if poly.points.length == 3
				newPolys.push poly

		if (infoResult)
			deletedPolys = @polygons.length - newPolys.length

		@polygons = newPolys
		return deletedPolys

	recalculateNormals: (infoResult) ->
		newNormals = 0
		for poly in @polygons
			d1 = poly.points[1].minus poly.points[0]
			d2 = poly.points[2].minus poly.points[0]
			n = d1.crossProduct d2
			n = n.normalized()

			if infoResult
				if poly.normal?
					dist = poly.normal.euclideanDistanceTo n
					if (dist > 0.001)
						newNormals++
				else
					newNormals++

			poly.normal = n
		return newNormals

	cleanse: (infoResult = false) ->
		result = {}
		result.deletedPolygons = @removeInvalidPolygons infoResult
		result.recalculatedNormals = @recalculateNormals infoResult
		return result


class Poly
	constructor: () ->
		@points = []
		@normal = new Vec3(0, 0, 0)

	setNormal: (@normal) ->
		return undefined

	addPoint: (p) ->
		@points.push p


class Stl
	constructor: (stlBuffer, options) ->

		@modelObject = {}

		options ?= {}
		options.optimize ?= true
		options.cleanse ?= true

		if Buffer
			stlString = new Buffer(new Uint8Array(stlBuffer)).toString()

		else
			stlString = textEncoding
				.TextDecoder 'utf-8'
				.decode new Uint8Array stlBuffer


		# TODO: Just try to parse as Ascii and handle possible errors
		if stlString.startsWith('solid') and stlString.includes('facet') and
		stlString.includes ('vertex')
			try
				@modelObject = parseAscii stlString
			catch error
				console.error error
				@modelObject = parseBinary stlBuffer

		else @modelObject = parseBinary stlBuffer

		if options.optimize
			@modelObject = optimizeModel @modelObject, options

	model: () ->
		return @modelObject


module.exports = Stl
