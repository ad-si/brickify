# An optimized model structure with indexed faces / vertices
# and cached vertex and face normals
# Created by the stlImportPlugin

THREE = require 'three'

class OptimizedModel
	constructor: () ->
		@positions = []
		@indices = []
		@vertexNormals = []
		@faceNormals = []
		@originalFileName = 'Unknown file'

	# Checks whether the model is 2-manifold, meaning that each edge is connected
	# to exactly two faces. This also implies that the mesh is a closed body
	# without holes
	isTwoManifold: () ->
		if @_isTwoManifold?
			return @_isTwoManifold

		edges = []
		numEdges = []

		# adds the edge to the edges list. if it already exists in the list,
		# the counter in numEdges is increased
		addEdge = (a,b) ->
			for i in [0..edges.length - 1] by 1
				aeb = (edges[i].a == a and edges[i].b == b)
				bea = (edges[i].a == b and edges[i].b == a)
				if (aeb or bea)
					numEdges[i]++
					if numEdges[i] > 2
						return false
					else
						return true
			edges.push {a: a, b: b}
			numEdges.push 1

		# add all edges for all triangles
		for i in [0..@indices.length - 1] by 3
			a = @indices[i]
			b = @indices[i + 1]
			c = @indices[i + 2]
			r = addEdge a,b
			r = addEdge(b,c) and r
			r = addEdge(c,a) and r

			if not r
				@_isTwoManifold = false
				return @_isTwoManifold

		# check that each edge exists exactly twice
		for num in numEdges
			if num != 2
				@_isTwoManifold = false
				return @_isTwoManifold
		@_isTwoManifold = true
		return @_isTwoManifold

	toBase64: () ->
		posA = new Float32Array(@positions.length)
		for i in [0..@positions.length - 1]
			posA[i] = @positions[i]
		indA = new Int32Array(@indices.length)
		for i in [0..@indices.length - 1]
			indA[i] = @indices[i]
		vnA = new Float32Array(@vertexNormals.length)
		for i in [0..@vertexNormals.length - 1]
			vnA[i] = @vertexNormals[i]
		fnA = new Float32Array(@faceNormals.length)
		for i in [0..@faceNormals.length - 1]
			fnA[i] = @faceNormals[i]

		posBase = @arrayBufferToBase64 posA.buffer
		baseString = posBase
		baseString += '|'

		indBase = @arrayBufferToBase64 indA.buffer
		baseString += indBase
		baseString += '|'

		vnBase = @arrayBufferToBase64 vnA.buffer
		baseString += vnBase
		baseString += '|'

		fnBase = @arrayBufferToBase64 fnA.buffer
		baseString += fnBase

		baseString += '|' + @originalFileName

		return baseString
	fromBase64: (base64String) ->
		strArray = base64String.split '|'

		@positions = @base64ToFloat32Array strArray[0]
		@indices = new @base64ToInt32Array strArray[1]
		@vertexNormals = @base64ToFloat32Array strArray[2]
		@faceNormals = @base64ToFloat32Array strArray[3]
		@originalFileName = strArray[4]
	base64ToFloat32Array: (b64) ->
		numFloats =  (base64ByteLength b64.length) / 4
		result = new Float32Array(numFloats)
		decoded = stringToUint8Array atob(b64)
		pview = new DataView(decoded.buffer)
		for i in [0..numFloats - 1]
			result[i] = pview.getFloat32 i * 4, true
		return result
	base64ToInt32Array: (b64) ->
		numInts =  (base64ByteLength b64.length) / 4
		result = new Int32Array(numInts)
		decoded = stringToUint8Array atob(b64)
		pview = new DataView(decoded.buffer)
		for i in [0..numInts - 1]
			result[i] = pview.getInt32 i * 4, true
		return result
	arrayBufferToBase64: (buffer) ->
		binary = ''
		bytes = new Uint8Array( buffer )
		len = bytes.byteLength
		for i in [0..len - 1]
			binary += String.fromCharCode( bytes[ i ] )
		return window.btoa binary

	# Creates a ThreeGeometry out of an optimized model
	# if bufferGeoemtry is set to true, a BufferGeometry using
	# the vertex normals will be created
	# else, a normal Geometry with face normals will be created
	# (contains duplicate points, but provides better shading for sharp edges)
	convertToThreeGeometry: (bufferGeometry = false) ->
		if (bufferGeometry)
			return @createBufferGeometry()
		else
			return @createStandardGeometry()

	# Creates a THREE.BufferGeometry using vertex normals
	createBufferGeometry: ->
		geometry = new THREE.BufferGeometry()
		#officially, threejs supports normal array, but in fact,
		#you have to use this lowlevel datatype to view something
		parray = new Float32Array(@positions.length)
		for i in [0..@positions.length - 1]
			parray[i] = @positions[i]
		narray = new Float32Array(@vertexNormals.length)
		for i in [0..@vertexNormals.length - 1]
			narray[i] = @vertexNormals[i]
		iarray = new Uint32Array(@indices.length)
		for i in [0..@indices.length - 1]
			iarray[i] = @indices[i]

		geometry.addAttribute 'index', new THREE.BufferAttribute(iarray, 1)
		geometry.addAttribute 'position', new THREE.BufferAttribute(parray, 3)
		geometry.addAttribute 'normal', new THREE.BufferAttribute(narray, 3)
		geometry.computeBoundingSphere()
		return geometry

	# uses a THREE.Geometry using face normals
	createStandardGeometry: ->
		geometry = new THREE.Geometry()

		for vi in [0..@positions.length - 1] by 3
			geometry.vertices.push new THREE.Vector3(@positions[vi],
				@positions[vi + 1], @positions[vi + 2])

		for fi in [0..@indices.length - 1] by 3
			geometry.faces.push new THREE.Face3(@indices[fi],
				@indices[fi + 1], @indices[fi + 2],
				new THREE.Vector3(@faceNormals[fi],
					@faceNormals[fi + 1],
					@faceNormals[fi + 2]))

		return geometry

	boundingBox: ->
		if @_boundingBox
			return @_boundingBox

		minX = maxX = @positions[0]
		minY = maxY = @positions[1]
		minZ = maxZ = @positions[2]
		for i in [0..@positions.length - 1] by 3
			minX = @positions[i]     if @positions[i] < minX
			minY = @positions[i + 1] if @positions[i + 1] < minY
			minZ = @positions[i + 2] if @positions[i + 2] < minZ
			maxX = @positions[i]     if @positions[i] > maxX
			maxY = @positions[i + 1] if @positions[i + 1] > maxY
			maxZ = @positions[i + 2] if @positions[i + 2] > maxZ

		@_boundingBox = {
			min: {x: minX, y: minY, z: minZ}
			max: {x: maxX, y: maxY, z: maxZ}
		}
		return @_boundingBox

	isInsideModel: (p, gridOrigin = {x: 0, y: 0}) =>
		#determine whether this point is inside of the model
		#shoot a ray up the z-Axis and look what polygons we intersect
		gridX = Math.round(p.x - gridOrigin.x)
		gridY = Math.round(p.y - gridOrigin.y)

		if @polyheightssaved?[gridX]?[gridY]?
			polyheights = @polyheightssaved[gridX][gridY]
		else
			intersectedPolygons = []

			for i in [0..@indices.length - 1] by 3
				p0 = {
					x: @positions[@indices[i] * 3]
					y: @positions[@indices[i] * 3 + 1]
					z: @positions[@indices[i] * 3 + 2]
				}
				p1 = {
					x: @positions[@indices[i + 1] * 3]
					y: @positions[@indices[i + 1] * 3 + 1]
					z: @positions[@indices[i + 1] * 3 + 2]
				}
				p2 = {
					x: @positions[@indices[i + 2] * 3]
					y: @positions[@indices[i + 2] * 3 + 1]
					z: @positions[@indices[i + 2] * 3 + 2]
				}

				#2d is point in triangle
				#http://stackoverflow.com/questions/
				# 2049582/how-to-determine-a-point-in-a-triangle
				A = 0.5 * (-p1.y * p2.x + p0.y *
						(-p1.x + p2.x) + p0.x * (p1.y - p2.y) + p1.x * p2.y)
				sign = 1
				sign = -1 if A < 0

				s = (p0.y * p2.x - p0.x * p2.y +
						(p2.y - p0.y) * p.x + (p0.x - p2.x) * p.y) * sign;
				t = (p0.x * p1.y - p0.y * p1.x +
						(p0.y - p1.y) * p.x + (p1.x - p0.x) * p.y) * sign;

				if (s >= 0) and (t >= 0) and ((s + t) < (2 * A * sign))
					# point is in triangle
					intersectedPolygons.push {a: p0, b: p1, c: p2, sign: sign}

			#extract polygon heights
			polyheights = []
			for poly in intersectedPolygons
				a = poly.a
				b = poly.b
				c = poly.c

				da = Math.sqrt((a.x - p.x) * (a.x - p.x) + (a.y - p.y) * (a.y - p.y))
				db = Math.sqrt((b.x - p.x) * (b.x - p.x) + (b.y - p.y) * (b.y - p.y))
				dc = Math.sqrt((c.x - p.x) * (c.x - p.x) + (c.y - p.y) * (c.y - p.y))
				dsum = da + db + dc
				z = a.z * (da / dsum) + b.z * (db / dsum) + c.z * (dc / dsum)

				###
				duplicated = false
				for h in polyheights
					if Math.abs(z - h) < 0.0000001
						duplicated = true
						break
				if not duplicated
					polyheights.push z
				###
				polyheights.push {z: z, sign: poly.sign}

			polyheights.sort (a,b) ->
				if a.z < b.z
					return -1
				else if a.z > b.z
					return 1
				else
					return 0

			if not @polyheightssaved?
				@polyheightssaved = new Array()
			if not @polyheightssaved[gridX]?
				@polyheightssaved[gridX] = new Array()

			@polyheightssaved[gridX][gridY] = polyheights

		#go to the z index that is above our height
		inside = false
		aboveTestPoint = false
		polysAboveTestPoint = 0
		polysBelowTestPoint = 0
		for ph in polyheights
			if ph.z > p.z
				aboveTestPoint = true
				polysAboveTestPoint++
			else
				polysBelowTestPoint++

			if not aboveTestPoint
				if ph.sign == -1
					inside = true
				else
					inside = false
			else #if aboveTestPoint
				if inside and ph.sign == 1
					# the next polygon is outwards facing and we were inside
					break

		if inside and polysAboveTestPoint % 2 == 1 and polysBelowTestPoint > 0
			return true
		else
			#if polyheights.length > 0
			#	console.log "Not in polygon:"
			#	console.log p
			#	console.log polyheights
			return false

module.exports = OptimizedModel

base64ByteLength = (base64Length) ->
	return (base64Length / 4) * 3

stringToUint8Array = (str) ->
	ab = new ArrayBuffer(str.length)
	uintarray = new Uint8Array(ab)
	for i in [0..str.length - 1]
		uintarray[i] = str.charCodeAt i
	return uintarray
