###
# @module interactionHelper
###

THREE = require 'three'

###
# Determines the intersections a ray casted by a screen space interaction hits
# @param {Object} event usually a mouse or tap or pointer event
# @param {Number} event.pageX the x coordinate on the screen
# @param {Number} event.pageY the y coordinate on the screen
# @param {Array<Object>} objects the three nodes which take part in ray casting
# @param {Renderer} renderer the renderer that provides the camera and canvas
# @return {Array<Object>} an array of intersections
# @memberOf interactionHelper
###
getIntersections = (event, objects, renderer) ->
	ray = calculateRay event, renderer

	raycaster = new THREE.Raycaster()
	raycaster.ray.set renderer.getCamera().position, ray

	return raycaster.intersectObjects objects, true
module.exports.getIntersections = getIntersections

###
# Determines the position of an event on the z=0 plane
# @param {Object} event usually a mouse or tap or pointer event
# @param {Number} event.pageX the x coordinate on the screen
# @param {Number} event.pageY the y coordinate on the screen
# @param {Renderer} renderer the renderer that provides the camera and canvas
# @return {Object} a vector {x, y, z}
# @memberOf interactionHelper
###
calculatePositionOnGrid = (event, renderer) ->
	ray = calculateRay event, renderer

	# we are calculating in camera coordinate system -> y and z are rotated
	camera = renderer.getCamera()
	ray.multiplyScalar -camera.position.y / ray.y
	posInWorld = camera.position.clone().add ray

	return x: posInWorld.x, y: -posInWorld.z, z: posInWorld.y
module.exports.getGridPosition = calculatePositionOnGrid

###
# Determines the position of an event in canvas space
# @param {Object} event usually a mouse or tap or pointer event
# @param {Number} event.pageX the x coordinate on the screen
# @param {Number} event.pageY the y coordinate on the screen
# @param {Renderer} renderer the renderer that provides the camera and canvas
# @return {Object} a three vector
# @memberOf interactionHelper
###
calculatePositionInCanvasSpace = (event, renderer) ->
	canvas = renderer.getDomElement()

	return new THREE.Vector3(
		(event.pageX / canvas.width) * 2 - 1
		(-event.pageY / canvas.height) * 2 + 1
		0.5
	)
module.exports.calculatePositionInCanvasSpace = calculatePositionInCanvasSpace

###
# Determines the position of the event in camera space
# @param {Object} event usually a mouse or tap or pointer event
# @param {Number} event.pageX the x coordinate on the screen
# @param {Number} event.pageY the y coordinate on the screen
# @param {Renderer} renderer the renderer that provides the camera and canvas
# @return {Object} a three vector
# @memberOf interactionHelper
###
calculatePositionInCameraSpace = (event, renderer) ->
	positionInCanvasCS = calculatePositionInCanvasSpace event, renderer
	return positionInCanvasCS.unproject renderer.getCamera()
module.exports.calculatePositionInCameraSpace = calculatePositionInCameraSpace

###
# Determines a virtual ray that a screen space interaction casts
# @param {Object} event usually a mouse or tap or pointer event
# @param {Number} event.pageX the x coordinate on the screen
# @param {Number} event.pageY the y coordinate on the screen
# @param {Renderer} renderer the renderer that provides the camera and canvas
# @return {Object} a normalized three vector {x, y, z}
# @memberOf interactionHelper
###
calculateRay = (event, renderer) ->
	positionInCameraCS = calculatePositionInCameraSpace event, renderer
	return positionInCameraCS.sub(renderer.getCamera().position).normalize()
module.exports.calculateRay = calculateRay
