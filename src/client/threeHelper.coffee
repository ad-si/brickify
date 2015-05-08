THREE = require 'three'

module.exports.link = (node, threeNode) ->
	threeNode.brickifyNode = node.id

module.exports.find = (node, threeParentNode) ->
	threeParentNode.getObjectByProperty 'brickifyNode', node.id, true

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
