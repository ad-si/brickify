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
					currentPoly.addPoint new Vec3d(vx, vy, vz)
	return stl

module.exports.convertToThreeGeometry = (stlModel,
																				 pointDistanceEpsilon = 0.0001) ->
	geometry = new THREE.BufferGeometry()

	positions = []#xyz xyz xyz
	normal = [] # t1 t2 t3
	index = [] #vert1 vert2 vert3

	for poly in stlModel.polygons
		#add points if they don't exist, or get index of these points
		indices = [-1,-1,-1]
		for pi in [0..2]
			point = poly.points[pi]
			for gi in  [0..positions.length-1] by 3
				geopoint = new Vec3d(positions[gi], positions[gi+1], positions[gi+2])
				if (point.euclideanDistanceTo geopoint) < pointDistanceEpsilon
					indices[pi] = gi / 3
					break
			if indices[pi] == -1
				indices[pi] = positions.length / 3
				positions.push point.x
				positions.push point.y
				positions.push point.z

		index.push indices[0]
		index.push indices[1]
		index.push indices[2]
		normal.push poly.normal.x
		normal.push poly.normal.y
		normal.push poly.normal.z

	geometry.addAttribute('position', new THREE.BufferAttribute(positions, 3))
	geometry.addAttribute('normal', new THREE.BufferAttribute(normal, 3))
	geometry.addAttribute('index', new THREE.BufferAttribute(index, 1))
	return geometry


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
	euclideanDistanceTo: (vec) ->
		return (@minus vec).length()
	multiplyScalar: (scalar) ->
		return new Vec3d(@x * scalar, @y * scalar, @z * scalar)
	normalized: () ->
		return @multiplyScalar (1.0/@length())

module.exports.Vec3d = Vec3d

String.prototype.startsWith = (str) ->
	return this.indexOf(str) == 0
