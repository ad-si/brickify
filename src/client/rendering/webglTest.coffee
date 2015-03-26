initGl = ->
	canvas = document.getElementById 'glCanvas'
	gl = canvas.getContext('webgl', {stencil: true})

	gl.clearColor(0,0,0,1)
	gl.enable(gl.DEPTH_TEST)
	gl.depthFunc(gl.LEQUAL)

	return gl

lastTime = 0
updateFps = (timestamp) ->
	if not lastTime > 0
		lastTime = timestamp
		return

	delta = timestamp - lastTime
	lastTime = timestamp

	fps = 1000 / delta
	window.document.title = fps.toFixed(2)

onPaint = (timestamp) ->
	gl.clear( gl.COLOR_BUFFER_BIT, gl.DEPTH_BUFFER_BIT, gl.STENCIL_BUFFER_BIT)
	updateFps timestamp

	requestAnimationFrame onPaint

gl = initGl()
window.requestAnimationFrame onPaint
