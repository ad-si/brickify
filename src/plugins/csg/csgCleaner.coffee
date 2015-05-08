clean = (geometry, options) ->
	if options.split
		geometries = splitGeometry geometry
	if options.filterSmallGeometries
		geometries = filterSmallGeometries geometries, options.minimalPrintVolume
	return geometries

filterSmallGeometries = (geometries, minimalPrintVolume) ->
	filteredGeometries = []
	for geometry in geometries
		volume = getVolume geometry
		if volume > minimalPrintVolume
			filteredGeometries.push geometry
	return filteredGeometries

###
# calculates the volume of threeGeometry
# see http://stackoverflow.com/questions/1410525
# @param {THREE.Geometry} threeGeometry an instance of three geometry
# @return {Number} volume in mm^3
###
getVolume = (threeGeometry) ->
	volume = 0
	forAllFaces threeGeometry, (a, b, c) ->
		volume += (a.x * b.y * c.z) + (a.y * b.z * c.x) + (a.z * b.x * c.y) - \
				(a.x * b.z * c.y) - (a.y * b.x * c.z) - (a.z * b.y * c.x)
	return volume / 6

forAllFaces = (threeGeometry, visitor) ->
	faces = threeGeometry.faces
	vertices = threeGeometry.vertices

	for face in faces
		a = vertices[face.a]
		b = vertices[face.b]
		c = vertices[face.c]
		visitor a, b, c

splitGeometry = (geometry) ->
	geometry.mergeVertices()
	connectedComponents = getConnectedComponents geometry
	if connectedComponents.length is 1
		return [geometry]

	geometries = []
	for component in connectedComponents
		geometries.push buildGeometry(component, geometry)

	return geometries

buildGeometry = (hashmap, baseGeometry) ->
	geometry = new THREE.Geometry()
	hashmap.faceIndices.forEach (faceIndex) ->
		face = baseGeometry.faces[faceIndex]
		length = geometry.vertices.length
		geometry.vertices.push(
			baseGeometry.vertices[face.a]
			baseGeometry.vertices[face.b]
			baseGeometry.vertices[face.c]
		)
		geometry.faces.push(
			new THREE.Face3 length, length + 1, length + 2, face.normal
		)

	geometry.mergeVertices()
	geometry.verticesNeedUpdate = true
	geometry.elementsNeedUpdate = true

	return geometry

getConnectedComponents = (geometry) ->
	equivalenceClasses = []

	return equivalenceClasses if geometry.faces.length is 0

	for i in [0..geometry.faces.length - 1]
		face = geometry.faces[i]
		a = face.a
		b = face.b
		c = face.c
		connectedClasses = []

		for equivalenceClass in equivalenceClasses
			if equivalenceClass.vertexIndices.has(a) or
			equivalenceClass.vertexIndices.has(b) or
			equivalenceClass.vertexIndices.has(c)
				equivalenceClass.vertexIndices.add a
				equivalenceClass.vertexIndices.add b
				equivalenceClass.vertexIndices.add c
				equivalenceClass.faceIndices.add i
				connectedClasses.push equivalenceClass

		if connectedClasses.length is 0
			equivalenceClass = {
				vertexIndices: new Set()
				faceIndices: new Set()
			}
			equivalenceClass.vertexIndices.add a
			equivalenceClass.vertexIndices.add b
			equivalenceClass.vertexIndices.add c
			equivalenceClass.faceIndices.add i
			equivalenceClasses.push equivalenceClass

		else if connectedClasses.length > 1
			compactClasses connectedClasses
			equivalenceClasses = equivalenceClasses.filter (a) ->
				a.faceIndices.size > 0

	return equivalenceClasses

compactClasses = (equivalenceClasses) ->
	vertexIndices = equivalenceClasses[0].vertexIndices
	faceIndices = equivalenceClasses[0].faceIndices

	for i in [1..equivalenceClasses.length - 1] by 1
		equivalenceClass = equivalenceClasses[i]
		equivalenceClass.vertexIndices.forEach (vertex) ->
			vertexIndices.add vertex
		equivalenceClass.faceIndices.forEach (faceIndex) ->
			faceIndices.add faceIndex

		# clear old class
		equivalenceClass.vertexIndices.clear()
		equivalenceClass.faceIndices.clear()

module.exports.clean = clean
