clean = (geometry, options) ->
	geometries = splitGeometry geometry
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
	geometries = []
	for component in connectedComponents
		geometries.push buildGeometry(component, geometry)

	return geometries

buildGeometry = (hashmap, baseGeometry) ->
	geometry = new THREE.Geometry()
	hashmap.faceIndices.forEach (faceIndex) ->
		face = baseGeometry.faces[faceIndex]
		geometry.vertices.push baseGeometry.vertices[face.a]
		aIndex = geometry.vertices.length - 1
		geometry.vertices.push baseGeometry.vertices[face.b]
		bIndex = geometry.vertices.length - 1
		geometry.vertices.push baseGeometry.vertices[face.c]
		cIndex = geometry.vertices.length - 1
		geometry.faces.push new THREE.Face3 aIndex, bIndex, cIndex, face.normal

	geometry.mergeVertices()
	geometry.verticesNeedUpdate = true
	geometry.elementsNeedUpdate = true

	return geometry

getConnectedComponents = (geometry) ->
	equivalenceClasses = []

	return equivalenceClasses if geometry.faces.length is 0

	for i in [0..geometry.faces.length - 1]
		face = geometry.faces[i]
		connectedClasses = []

		for equivalenceClass in equivalenceClasses
			if equivalenceClass.vertexIndices.has(face.a) or
			equivalenceClass.vertexIndices.has(face.b) or
			equivalenceClass.vertexIndices.has(face.c)
				equivalenceClass.vertexIndices.add face.a
				equivalenceClass.vertexIndices.add face.b
				equivalenceClass.vertexIndices.add face.c
				equivalenceClass.faceIndices.add i
				connectedClasses.push equivalenceClass

		if connectedClasses.length is 0
			equivalenceClass = {
				vertexIndices: new Set()
				faceIndices: new Set()
			}
			equivalenceClass.vertexIndices.add face.a
			equivalenceClass.vertexIndices.add face.b
			equivalenceClass.vertexIndices.add face.c
			equivalenceClass.faceIndices.add i
			equivalenceClasses.push equivalenceClass

		else if connectedClasses.length > 1
			combined = compactClasses connectedClasses
			equivalenceClasses.push combined
			equivalenceClasses = equivalenceClasses.filter (a) ->
				a.faceIndices.size > 0

	return equivalenceClasses

compactClasses = (equivalenceClasses) ->
	newClass =  {
		vertexIndices: new Set()
		faceIndices: new Set()
	}

	for eq in equivalenceClasses
		# add points and polygons to new class. The hashmap
		# automatically prevents inserting duplicate values
		eq.vertexIndices.forEach (vertex) ->
			newClass.vertexIndices.add vertex
		eq.faceIndices.forEach (faceIndex) ->
			newClass.faceIndices.add faceIndex

		# clear old class
		eq.vertexIndices.clear()
		eq.faceIndices.clear()

	return newClass

module.exports.clean = clean
