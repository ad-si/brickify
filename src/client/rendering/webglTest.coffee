shaderSources = require './webglTestShader'

lastTime = 0
updateFps = (timestamp) ->
	if not lastTime > 0
		lastTime = timestamp
		return

	delta = timestamp - lastTime
	lastTime = timestamp

	fps = 1000 / delta
	window.document.title = fps.toFixed(2)

initGl = ->
	canvas = document.getElementById 'glCanvas'
	gl = canvas.getContext('webgl', {stencil: true})

	gl.clearColor(0,0,0,1)
	gl.enable(gl.DEPTH_TEST)
	gl.depthFunc(gl.LEQUAL)

	gl.viewport(0,0, canvas.width, canvas.height)

	return gl

initQuadBuffer = (size = 1.0) ->
	quadBuffer = gl.createBuffer()
	gl.bindBuffer(gl.ARRAY_BUFFER, quadBuffer)
	vertices = [
		 1 * size,   1 * size, 0,
		-1 * size,   1 * size, 0,
		 1 * size,  -1 * size, 0,
		-1 * size,  -1 * size, 0
	]
	gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW)
	quadBuffer.itemSize = 3
	quadBuffer.numItems = 4
	return quadBuffer

compileShader = (shader, sourcecode) ->
	gl.shaderSource shader, sourcecode
	gl.compileShader shader

	if not gl.getShaderParameter shader, gl.COMPILE_STATUS
		console.warn 'Error compiling shader: '
		console.warn gl.getShaderInfoLog shader
		return null

	return shader

initShaderProgram = (vertex, fragment) ->
	# Compile shaders
	vertexCompiled = gl.createShader(gl.VERTEX_SHADER)
	fragmentCompiled = gl.createShader(gl.FRAGMENT_SHADER)

	vertexCompiled = compileShader(vertexCompiled, vertex)
	fragmentCompiled = compileShader(fragmentCompiled, fragment)

	return null if not (vertexCompiled? and fragmentCompiled?)

	program = gl.createProgram()

	gl.attachShader(program, vertexCompiled)
	gl.attachShader(program, fragmentCompiled)
	gl.linkProgram(program)

	if not gl.getProgramParameter(program, gl.LINK_STATUS)
		console.warn 'Unable to initialize shader program'
		return null

	# Link common attributes
	program.positionAttribute = gl.getAttribLocation(program, 'position')

	return program

paintPrimaryQuad = ->
	# bind shader
	gl.useProgram primaryShaderProgram
	gl.enableVertexAttribArray primaryShaderProgram.positionAttribute

	# draw quad
	gl.bindBuffer(gl.ARRAY_BUFFER, visibleQuadBuffer)
	gl.vertexAttribPointer(
		primaryShaderProgram.positionAttribute
		visibleQuadBuffer.itemSize, gl.FLOAT, false, 0, 0
	)
	
	gl.drawArrays(gl.TRIANGLE_STRIP, 0, visibleQuadBuffer.numItems)

onPaint = (timestamp) ->
	updateFps timestamp

	# init viewport
	gl.clear( gl.COLOR_BUFFER_BIT, gl.DEPTH_BUFFER_BIT, gl.STENCIL_BUFFER_BIT)

	paintPrimaryQuad()

	requestAnimationFrame onPaint

gl = initGl()
visibleQuadBuffer = initQuadBuffer(0.8)
primaryShaderProgram = initShaderProgram(
	shaderSources.vertexPrimary,shaderSources.fragmentPrimary
)

window.requestAnimationFrame onPaint
