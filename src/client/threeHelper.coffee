THREE = require 'three'

applyNodeTransforms = (node, threeNode) ->
	_set = (property, vector) -> property.set vector.x, vector.y, vector.z

	_set threeNode.position, node.transform.position
	_set threeNode.rotation, node.transform.rotation
	_set threeNode.scale, node.transform.scale

getTransformMatrix = (node) ->
	threeNode = new THREE.Object3D()
	applyNodeTransforms node, threeNode
	threeNode.updateMatrix()
	return threeNode.matrix

getBoundingSphere = (threeNode) ->
	geometry = threeNode.geometry
	geometry.computeBoundingSphere()
	result =
		radius: geometry.boundingSphere.radius
		center: geometry.boundingSphere.center

	threeNode.updateMatrix()
	threeNode.parent?.updateMatrixWorld()
	result.center.applyProjection threeNode.matrixWorld

	return result


module.exports = {
	link: (node, threeNode) ->
		threeNode.brickolageNode = node.id
	find: (node, threeParentNode) ->
		threeParentNode.getObjectByProperty 'brickolageNode', node.id, true
	applyNodeTransforms: applyNodeTransforms
	getTransformMatrix: getTransformMatrix
	getBoundingSphere: getBoundingSphere
}
