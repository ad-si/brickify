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
	if threeNode.geometry?
		geometry = threeNode.geometry
		geometry.computeBoundingSphere()
		boundingSphere = geometry.boundingSphere
		threeNode.updateMatrix()
		threeNode.parent?.updateMatrixWorld()
		boundingSphere.center.applyProjection threeNode.matrixWorld
		return boundingSphere
	else if threeNode instanceof THREE.Object3D
		boundingBox = new THREE.Box3().setFromObject threeNode
		size = boundingBox.size()
		radius = Math.sqrt(size.x * size.x + size.y * size.y + size.z * size.z) / 2
		center = boundingBox.center()
		return radius: radius, center: center

module.exports.zoomToBoundingSphere = (
	camera, scene, controls, boundingSphere) ->
	radius = boundingSphere.radius
	center = boundingSphere.center

	alpha = camera.fov
	distanceToObject = radius / Math.sin(alpha)

	rv = camera.position.clone()
	rv.sub controls.target if controls?
	rv = rv.normalize().multiplyScalar(distanceToObject)
	zoomAdjustmentFactor = 2.5
	rv = rv.multiplyScalar(zoomAdjustmentFactor)

	#apply scene transforms (e.g. rotation to make y the vector facing upwards)
	target = center.clone().applyMatrix4(scene.matrix)
	position = target.clone().add(rv)

	camera.position.set position.x, position.y, position.z
	camera.lookAt target

	_updateControls controls, position, target if controls?

_updateControls = (controls, position, target) ->
	controls.update()
	controls.target = controls.target0 = target.clone()
	controls.position = controls.position0 = position.clone()
	controls.reset()
