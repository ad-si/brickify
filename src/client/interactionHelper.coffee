renderer = require './renderer'
canvas = null

module.exports.onMouseEvent = (event) ->
	canvas ?= renderer.getDomElement()
	intersects = getPolygonClickedOn(event)

	###switch 1
		when 1 then currentInteraction.onLeftClick?(intersects)
		when 2 then currentInteraction.onMiddleClick?(intersects)
		when 3 then currentInteraction.onRightClick?(intersects)###

module.exports.getPolygonClickedOn = (event, objects) ->
	camera = renderer.getCamera()
	raycaster = new THREE.Raycaster()
	[x,y] = getRelativeCursorPosition event
	vector = new THREE.Vector3()
	relativeX = x / window.innerWidth * 2 - 1
	relativeY = y / window.innerHeight
	vector.set relativeX, -relativeY * 2 + 1, 0.5
	vector.unproject camera
	raycaster.ray.set(camera.position, vector.sub(camera.position).normalize())
	raycaster.intersectObjects objects, true

getCastingVector = (x, y) ->
	viewVector = getViewingVector x, y
	viewVector.unproject(renderer.getCamera())
	viewVector.normalize()

getViewingVector = (x, y) ->
	x = (x / canvas.clientWidth) * 2 - 1
	y = -(y / canvas.clientHeight) * 2 + 1
	new THREE.Vector3(x, y, 0.5)

getRelativeCursorPosition = (event) ->
	###
  # use this if the canvas is no longer located at (0,0) within the window
	currentElement = renderer.getDomElement()
	x = event.pageX - (currentElement.offsetLeft - currentElement.scrollLeft)
	y = event.pageY - (currentElement.offsetTop - currentElement.scrollTop)
	while currentElement = currentElement.offsetParent
		x -= currentElement.offsetLeft - currentElement.scrollLeft
		y -= currentElement.offsetTop - currentElement.scrollTop
  [x, y]
	###
	[event.pageX, event.pageY]
