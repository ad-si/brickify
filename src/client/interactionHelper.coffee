THREE = require 'three'

getPolygonClickedOn = (event, objects, renderer) ->
	camera = renderer.getCamera()
	raycaster = new THREE.Raycaster()
	x = event.pageX
	y = event.pageY
	relativeX = x / window.innerWidth * 2 - 1
	relativeY = y / window.innerHeight
	vector = new THREE.Vector3 relativeX, -relativeY * 2 + 1, 0.5
	vector.unproject camera
	raycaster.ray.set(camera.position, vector.sub(camera.position).normalize())
	raycaster.intersectObjects objects, true

module.exports.getPolygonClickedOn = getPolygonClickedOn

###
# Calculates the position on the z=0 plane in 3d space from given screen
# (mouse) coordinates.
#
# @param {Number} screenX the x coordinate of the mouse event
# @param {Number} screenY the y coordinate of the mouse event
# @memberOf
###
getGridPosition = (event, renderer) ->
	canvas = renderer.getDomElement()
	camera = renderer.getCamera()

	posInCanvas = new THREE.Vector3(
		(event.pageX / canvas.width) * 2 - 1
		(-event.pageY / canvas.height) * 2 + 1
		0.5
	)

	posInCamera = posInCanvas.clone().unproject camera

	ray = posInCamera.sub(camera.position).normalize()
	# we are calculating in camera coordinate system -> y and z are rotated
	ray.multiplyScalar -camera.position.y / ray.y
	posInWorld = camera.position.clone().add ray

	posInScene = new THREE.Vector3 posInWorld.x, -posInWorld.z, posInWorld.y
	return posInScene

module.exports.getGridPosition = getGridPosition
