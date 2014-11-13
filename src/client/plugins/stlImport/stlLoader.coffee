#parses the content of the file
module.exports.parse = (fileContent, errorCallback) ->
	model = null

	startsWithSolid = false
	hasFacet = false
	hasVertex = false
	if fileContent.indexOf("solid") == 0
		startsWithSolid = true
		if fileContent.indexOf("facet") > 0
			hasFacet = true
		if fileContent.indexOf("vertex") > 0
			hasVertex = true

	if !startsWithSolid
		#Import binary, since 'solid' is reserved for ascii
		model = parseBinary	toArrayBuffer fileContent
	else
		#Okay, it should be ascii. does it contain other keywords?
		if hasFacet and hasVertex
			model = parseAscii fileContent
		else
			#No facet and vertex? maybe it's a binary
			#that uses the solid keyword (it is not allowed to do so!)
			model = parseBinary	toArrayBuffer fileContent

	if model.importErrors.length > 0
		if errorCallback?
			errorCallback model.importErrors
	return model

toArrayBuffer = (buf) ->
	if typeof buf is "string"
		array_buffer = new Uint8Array(buf.length)
		i = 0

		while i < buf.length
			array_buffer[i] = buf.charCodeAt(i) & 0xff # implicitly assumes little-endian
			i++
		return array_buffer.buffer or array_buffer
	else
		return buf

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

parseBinary = (fileContent) ->
	stl = new Stl()
	reader = new DataView(fileContent,80)
	numTriangles = reader.getUint32 0, true

	#check if file size matches with numTriangles
	datalength = fileContent.byteLength - 80 - 4
	polyLength = 50
	calcDataLength = polyLength * numTriangles

	if (calcDataLength > datalength)
		stl.addError "Calculated length of triangle data does not match filesize,
		triangles might be missing"

	binaryIndex = 4
	while binaryIndex + polyLength <= datalength
		poly = new StlPoly()
		nx = reader.getFloat32 binaryIndex, true
		binaryIndex += 4
		ny = reader.getFloat32 binaryIndex, true
		binaryIndex += 4
		nz = reader.getFloat32 binaryIndex, true
		binaryIndex += 4
		poly.setNormal new Vec3d(nx, ny, nz)
		for i in [0..2]
			vx = reader.getFloat32 binaryIndex, true
			binaryIndex += 4
			vy = reader.getFloat32 binaryIndex, true
			binaryIndex += 4
			vz = reader.getFloat32 binaryIndex, true
			binaryIndex += 4
			poly.addPoint new Vec3d(vx,vy,vz)
		#skip uint 16
		binaryIndex += 2
		stl.addPolygon poly

	return stl

createBufferGeometry = (optimizedModel) ->
	geometry = new THREE.BufferGeometry()
	#officially, threejs supports normal array, but in fact,
	#you have to use this lowlevel datatype to view something
	parray = new Float32Array(optimizedModel.positions.length)
	for i in [0..optimizedModel.positions.length - 1]
		parray[i] = optimizedModel.positions[i]
	narray = new Float32Array(optimizedModel.vertexNormals.length)
	for i in [0..optimizedModel.vertexNormals.length - 1]
		narray[i] = optimizedModel.vertexNormals[i]
	iarray = new Uint32Array(optimizedModel.indices.length)
	for i in [0..optimizedModel.indices.length - 1]
		iarray[i] = optimizedModel.indices[i]

	geometry.addAttribute 'index', new THREE.BufferAttribute(iarray, 1)
	geometry.addAttribute 'position', new THREE.BufferAttribute(parray, 3)
	geometry.addAttribute 'normal', new THREE.BufferAttribute(narray, 3)
	geometry.computeBoundingSphere()
	return geometry

createStandardGeometry = (optimizedModel) ->
	geometry = new THREE.Geometry()

	for vi in [0..optimizedModel.positions.length-1] by 3
		geometry.vertices.push new THREE.Vector3(optimizedModel.positions[vi],
			optimizedModel.positions[vi+1], optimizedModel.positions[vi+2])

	for fi in [0..optimizedModel.indices.length-1] by 3
		geometry.faces.push new THREE.Face3(optimizedModel.indices[fi],
			optimizedModel.indices[fi+1], optimizedModel.indices[fi+2],
			new THREE.Vector3(optimizedModel.faceNormals[fi],
				optimizedModel.faceNormals[fi+1],
				optimizedModel.faceNormals[fi+2]))

	return geometry

#Creates a ThreeGeometry
#if bufferGeoemtry is set to true, a BufferGeometry using
#the vertex normals will be created
#else, a normal Geometry with face normals will be created
#(contains duplicate points, but provides better shading for sharp edges)
module.exports.convertToThreeGeometry = (stlModel, bufferGeometry = false) ->
	optimized = optimizeModel stlModel

	if (bufferGeometry)
		return createBufferGeometry(optimized)
	else
		return createStandardGeometry(optimized)

optimizeModel = (importedStl, pointDistanceEpsilon = 0.0001) ->
	positions = []#xyz xyz xyz
	vertexnormals = []
	faceNormals = []
	index = [] #vert1 vert2 vert3

	for poly in importedStl.polygons
		#add points if they don't exist, or get index of these points
		indices = [-1,-1,-1]
		for vertexIndex in [0..2]
			point = poly.points[vertexIndex]
			for geoPointIndex in  [0..positions.length-1] by 3
				geopoint = new Vec3d(positions[geoPointIndex],
					positions[geoPointIndex+1],
					positions[geoPointIndex+2])
				if (point.euclideanDistanceTo geopoint) < pointDistanceEpsilon
					indices[vertexIndex] = geoPointIndex / 3
					break
			if indices[vertexIndex] == -1
				indices[vertexIndex] = positions.length / 3
				positions.push point.x
				positions.push point.y
				positions.push point.z
				vertexnormals.push [
					new Vec3d(poly.normal.x, poly.normal.y, poly.normal.z)]
		index.push indices[0]
		index.push indices[1]
		index.push indices[2]
		faceNormals.push poly.normal.x
		faceNormals.push poly.normal.y
		faceNormals.push poly.normal.z

	#average all vertexnormals
	avgNormals = []
	for normalList in vertexnormals
		avg = new Vec3d(0,0,0)
		for normal in normalList
			normal = normal.normalized()
			avg = avg.add normal
		avg = avg.normalized()

		avgNormals.push avg.x
		avgNormals.push avg.y
		avgNormals.push avg.z

	optimized = new OptimizedModel()
	optimized.positions = positions
	optimized.indices = index
	optimized.vertexNormals = avgNormals
	optimized.faceNormals = faceNormals

	return optimized
module.exports.optimizeModel = optimizeModel

class OptimizedModel
	constructor: ()->
		@positions = []
		@indices = []
		@vertexNormals = []
		@faceNormals = []
module.exports.OptimizedModel = OptimizedModel

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
	add: (vec) ->
		return new Vec3d(@x + vec.x, @y + vec.y, @z + vec.z)
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
