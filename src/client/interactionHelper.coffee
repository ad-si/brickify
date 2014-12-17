THREE = require 'three'

module.exports.getPolygonClickedOn = (event, objects, renderer) ->
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
