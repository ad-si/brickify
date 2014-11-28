# An optimized model structure with indexed faces / vertices
# and cached vertex and face normals
# Created by the stlImportPlugin
class OptimizedModel
	constructor: () ->
		@positions = []
		@indices = []
		@vertexNormals = []
		@faceNormals = []

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
		if @_b64String?
			return @_b64String

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

		@_b64String = baseString
		return @_b64String
	fromBase64: (base64String) ->
		@_b64String = base64String
		strArray = base64String.split '|'

		@positions = @base64ToFloat32Array strArray[0]
		@indices = new @base64ToInt32Array strArray[1]
		@vertexNormals = @base64ToFloat32Array strArray[2]
		@faceNormals = @base64ToFloat32Array strArray[3]
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

module.exports = OptimizedModel

base64ByteLength = (base64Length) ->
	return (base64Length / 4) * 3

stringToUint8Array = (str) ->
	ab = new ArrayBuffer(str.length)
	uintarray = new Uint8Array(ab)
	for i in [0..str.length - 1]
		uintarray[i] = str.charCodeAt i
	return uintarray
