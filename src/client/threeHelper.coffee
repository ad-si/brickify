module.exports.link = (node, threeNode) ->
	threeNode.brickolageNode = node.id

module.exports.find = (node, threeParentNode) ->
	threeParentNode.getObjectByProperty 'brickolageNode', node.id, true

module.exports.applyNodeTransforms = (node, threeNode) ->
	_set = (property, vector) -> property.set vector.x, vector.y, vector.z

	_set threeNode.position, node.transform.position
	_set threeNode.rotation, node.transform.rotation
	_set threeNode.scale, node.transform.scale
