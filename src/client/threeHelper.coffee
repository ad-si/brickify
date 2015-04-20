THREE = require 'three'

module.exports.link = (node, threeNode) ->
	threeNode.brickolageNode = node.id

module.exports.find = (node, threeParentNode) ->
	threeParentNode.getObjectByProperty 'brickolageNode', node.id, true

applyNodeTransforms = (node, threeNode) ->
	_set = (property, vector) -> property.set vector.x, vector.y, vector.z

	_set threeNode.position, node.transform.position
	_set threeNode.rotation, node.transform.rotation
	_set threeNode.scale, node.transform.scale
module.exports.applyNodeTransforms = applyNodeTransforms

module.exports.getTransformMatrix = (node) ->
	threeNode = new THREE.Object3D()
	applyNodeTransforms node, threeNode
	threeNode.updateMatrix()
	return threeNode.matrix

module.exports.getBoundingSphere = (threeNode) ->
	geometry = threeNode.geometry
	geometry.computeBoundingSphere()
	result =
		radius: geometry.boundingSphere.radius
		center: geometry.boundingSphere.center

	threeNode.updateMatrix()
	threeNode.parent?.updateMatrixWorld()
	result.center.applyProjection threeNode.matrixWorld

	return result

forAllFaces = (threeGeometry, visitor) ->
	faces = threeGeometry.faces
	vertices = threeGeometry.vertices

	for face in faces
		a = vertices[face.a]
		b = vertices[face.b]
		c = vertices[face.c]
		visitor a, b, c

# see http://stackoverflow.com/questions/1410525
getVolume = (threeGeometry) ->
	volume = 0
	forAllFaces threeGeometry, (a, b, c) ->
		volume += (a.x * b.y * c.z) + (a.y * b.z * c.x) + (a.z * b.x * c.y) - \
		(a.x * b.z * c.y) - (a.y * b.x * c.z) - (a.z * b.y * c.x)
	return volume / 6 / 1000 # return volume in cm^3

getSurface = (threeGeometry) ->
	surface = 0
	forAllFaces threeGeometry, (a, b, c) ->
		ab = new THREE.Vector3 b.x - a.x, b.y - a.y, b.z - a.z
		ac = new THREE.Vector3 c.x - a.x, c.y - a.y, c.z - a.z
		surface += ab.cross(ac).length()
	return surface / 2 / 100 # return surface in cm^2

getHeight = (threeGeometry) ->
	vertices = threeGeometry.vertices
	return if vertices.length is 0

	minZ = vertices[0].z
	maxZ = vertices[0].z

	for vertex in vertices
		minZ = Math.min vertex.z, minZ
		maxZ = Math.max vertex.z, maxZ

	height = maxZ - minZ
	return height / 10 # return height in cm

# time approximation taken from MakerBot Desktop software configured for
# Replicator 5th Generation
module.exports.getPrintingTimeEstimate = (geometry) ->
	height = getHeight geometry
	surface = getSurface geometry
	volume = getVolume geometry
	return 2 + 2 * height + 0.3 * surface + 2.5 * volume
