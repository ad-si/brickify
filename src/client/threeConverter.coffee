module.exports.toStandardGeometry = (modelObject) ->

	{
		vertexCoordinates
		faceVertexIndices
		faceNormalCoordinates
	} = modelObject.mesh.faceVertex

	geometry = new THREE.Geometry()

	for vi in [0..vertexCoordinates.length - 1] by 3
		geometry.vertices.push new THREE.Vector3(
			vertexCoordinates[vi],
			vertexCoordinates[vi + 1],
			vertexCoordinates[vi + 2]
		)

	for fi in [0..faceVertexIndices.length - 1] by 3
		geometry.faces.push new THREE.Face3(
			faceVertexIndices[fi],
			faceVertexIndices[fi + 1],
			faceVertexIndices[fi + 2],
			new THREE.Vector3(
				faceNormalCoordinates[fi],
				faceNormalCoordinates[fi + 1],
				faceNormalCoordinates[fi + 2]
			)
		)

	return geometry

module.exports.toBufferGeometry = (modelObject) ->

	{
		vertexCoordinates
		faceVertexIndices
		vertexNormalCoordinates
	} = modelObject.mesh.faceVertex

	geometry = new THREE.BufferGeometry()
	#officially, threejs supports normal array, but in fact,
	#you have to use this lowlevel datatype to view something
	parray = new Float32Array vertexCoordinates.length
	for i in [0..vertexCoordinates.length - 1]
		parray[i] = vertexCoordinates[i]

	narray = new Float32Array vertexNormalCoordinates.length
	for i in [0..vertexNormalCoordinates.length - 1]
		narray[i] = vertexNormalCoordinates[i]

	iarray = new Uint32Array faceVertexIndices.length
	for i in [0..faceVertexIndices.length - 1]
		iarray[i] = faceVertexIndices[i]

	geometry.addAttribute 'index', new THREE.BufferAttribute(iarray, 1)
	geometry.addAttribute 'position', new THREE.BufferAttribute(parray, 3)
	geometry.addAttribute 'normal', new THREE.BufferAttribute(narray, 3)
	geometry.computeBoundingSphere()
	return geometry


module.exports.toModelObject = (threeGeometry, fileName) ->
	# clear data, if exists
	faceVertexMesh = {
		vertexCoordinates: []
		faceVertexIndices: []
		faceNormalCoordinates: []
	}

	# convert point positions
	for vertex in threeGeometry.vertices
		faceVertexMesh.vertexCoordinates.push vertex.x
		faceVertexMesh.vertexCoordinates.push vertex.y
		faceVertexMesh.vertexCoordinates.push vertex.z

	# convert polygons (indexed) and their normals
	for face in threeGeometry.faces
		faceVertexMesh.faceVertexIndices.push face.a
		faceVertexMesh.faceVertexIndices.push face.b
		faceVertexMesh.faceVertexIndices.push face.c

		faceVertexMesh.faceNormalCoordinates.push face.normal.x
		faceVertexMesh.faceNormalCoordinates.push face.normal.y
		faceVertexMesh.faceNormalCoordinates.push face.normal.z

	return {
		fileName: fileName || 'fromThreeGeometry'
		mesh:
			faceVertex: faceVertexMesh
	}
