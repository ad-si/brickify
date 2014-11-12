#parses the content of the file
module.exports.parse = (fileContent) ->
	model = null

	if fileContent.startsWith "solid"
		model = parseAscii fileContent
	else
		model = parseBinary	fileContent

	return model

parseAscii = (fileContent) ->
	astl = new AsciiStl(fileContent)
	stl = new Stl()

	currentPoly = null
	while !astl.reachedEnd()
		cmd = astl.nextText()
		cmd = cmd.toLowerCase()

		switch cmd
			when "solid"
				astl.nextText() #skip description of model
			when "facet"
				if (currentPoly?)
					stl.addError "Beginning a facet without ending the previous one"
					stl.addPolygon currentPoly
					currentPoly = null
				currentPoly = new StlPoly()
			when "endfacet"
				if !(currentPoly?)
					stl.addError "Ending a facet without beginning it"
				else
					stl.addPolygon currentPoly
					currentPoly = null
			when "normal"
				nx = parseFloat astl.nextText()
				ny = parseFloat astl.nextText()
				nz = parseFloat astl.nextText()

				if (!(nx?) || !(ny?) || !(nz?))
					stl.addError "Invalid normal definition: (#{nx}, #{ny}, #{nz})"
				else
					currentPoly.setNormal new Vec3d(nx,ny,nz)
			when "vertex"
				vx = parseFloat astl.nextText()
				vy = parseFloat astl.nextText()
				vz = parseFloat astl.nextText()

				if (!(vx?) || !(vy?) || !(vz?))
					stl.addError "Invalid vertex definition: (#{nx}, #{ny}, #{nz})"
				else
					currentPoly.addPoint = new Vec3d(vx, vy, vz)
	return stl

class AsciiStl
	constructor: (fileContent) ->
		@content = fileContent
		@index = 0
		@whitespaces = [' ', '\r', '\n', '\t', '\v', '\f']
	nextText: () ->
		@skipWhitespaces()
		cmd = @readUntilWhitespace();
	skipWhitespaces: () ->
		#moves the index to the next non whitespace character
		skip = true
		while skip
			if (@currentCharIsWhitespace() && !@reachedEnd())
				@index++
			else
				skip = false
	currentChar: () ->
		return @content[@index]
	currentCharIsWhitespace: () ->
		for space in @whitespaces
			if @currentChar() == space
				return true
		return false
	readUntilWhitespace: () ->
		readContent = ""
		while (!@currentCharIsWhitespace() && !@reachedEnd())
			readContent = readContent + @currentChar()
			@index++
		return readContent
	reachedEnd: () ->
		return (@index == @content.length)

class Stl
	constructor: () ->
		@polygons = []
		@importErrors = []
	addPolygon: (stlPolygon) ->
		@polygons.push(stlPolygon)
	addError: (string) ->
		@importErrors.push string
	removeInvalidPolygons: () ->
		newPolys = []
		for poly in @polygons
			#check if it has 3 vectors
			if poly.points.length == 3
				newPolys.push poly
		polygons = newPolys
	recalculateNormals: () ->
		for poly in @polygons
			d1 = poly.points[0] minus poly.points[1]
			d2 = poly.points[2] minus poly.points[1]
			n = d1 crossProduct d2
			n = n normalized()
			poly.normal = n
	cleanse: () ->
		@removeInvalidPolygons()
		@recalculateNormals()
module.exports.Stl = Stl

class StlPoly
	constructor: () ->
		@points = []
		@normal = new Vec3d(0,0,0)
	setNormal: (@normal) ->
	addPoint: (p) ->
		@points.push p
module.exports.Stlpoly = StlPoly

class Vec3d
	constructor: (@x, @y, @z) ->
	minus: (vec) ->
		return new Vec3d(@x - vec.x, @y - vec.y, @z - vec.z)
	crossProduct: (vec) ->
		return new Vec3d(@y*vec.z - @z-vec.y,
				@z*vec.x - @x*vec.z,
				@x*vec.y - @y*vec.x)
	length: () ->
		return Math.sqrt(@x*@x + @y*@y + @z*@z)
	multiplyScalar: (scalar) ->
		return new Vec3d(@x * scalar, @y * scalar, @z * scalar)
	normalized: () ->
		return @multiplyScalar (1.0/@length())


module.exports.Vec3d = Vec3d

String.prototype.startsWith = (str) ->
	return this.indexOf(str) == 0
