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

	# Three offcially supports normal arrays, but you actually
	# have to use this lowlevel datatype to view anything
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
