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

# see http://stackoverflow.com/questions/1410525
module.exports.getVolume = (threeGeometry) ->
	volume = 0
	faces = threeGeometry.faces
	vertices = threeGeometry.vertices

	for face in faces
		a = vertices[face.a]
		b = vertices[face.b]
		c = vertices[face.c]
		volume += (a.x * b.y * c.z) + (a.y * b.z * c.x) + (a.z * b.x * c.y) -\
		(a.x * b.z * c.y) - (a.y * b.x * c.z) - (a.z * b.y * c.x)

	return volume / 6 / 1000 # return volume in cm^3
