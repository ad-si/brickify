shaderSources = require './webglTestShader'

lastTime = 0
avgFps = 60
updateFps = (timestamp) ->
	if not lastTime > 0
		lastTime = timestamp
		return

	delta = timestamp - lastTime
	lastTime = timestamp

	fps = 1000 / delta
	avgFps =  (fps * 0.02) + ( avgFps * 0.98 )
	window.document.title = avgFps.toFixed(2)

initGl = ->
	# Initialize GL
	canvas = document.getElementById 'glCanvas'
	gl = canvas.getContext('webgl', {stencil: true})

	gl.clearColor(0,0,0,1)
	gl.enable(gl.DEPTH_TEST)
	gl.depthFunc(gl.LEQUAL)

	gl.viewport(0,0, canvas.width, canvas.height)
	gl.viewportWidth = canvas.width
	gl.viewportHeight = canvas.height

	# Initialize depth texture extension
	gl.getExtension('EXT_frag_depth')
	gl.getExtension('WEBGL_depth_texture')

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

	# Link common attributes and uniforms
	program.positionAttribute = gl.getAttribLocation(program, 'position')
	program.colorTextureUnifom = gl.getUniformLocation(program, 'colorTexture')
	program.depthTextureUnifom = gl.getUniformLocation(program, 'depthTexture')

	return program

createFramebuffer = (width, height) ->
	colorTexture = gl.createTexture()
	gl.bindTexture(gl.TEXTURE_2D, colorTexture)
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.texImage2D(
		gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null
	)

	depthTexture = gl.createTexture()
	gl.bindTexture(gl.TEXTURE_2D, depthTexture)
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
	gl.texImage2D(
		gl.TEXTURE_2D, 0, gl.DEPTH_COMPONENT, width, height, 0,
		gl.DEPTH_COMPONENT, gl.UNSIGNED_INT, null
	)

	framebuffer = gl.createFramebuffer()
	gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer)
	gl.framebufferTexture2D(
		gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, colorTexture, 0
	)
	gl.framebufferTexture2D(
		gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, depthTexture, 0
	)

	framebuffer.colorTexture = colorTexture
	framebuffer.depthTexture = depthTexture
	framebuffer.width = width
	framebuffer.height = height
	return framebuffer

paintQuadWithShader = (shader) ->
	# bind shader
	gl.useProgram shader
	gl.enableVertexAttribArray shader.positionAttribute

	# draw quad
	gl.bindBuffer(gl.ARRAY_BUFFER, visibleQuadBuffer)
	gl.vertexAttribPointer(
		shader.positionAttribute
		visibleQuadBuffer.itemSize, gl.FLOAT, false, 0, 0
	)
	
	gl.drawArrays(gl.TRIANGLE_STRIP, 0, visibleQuadBuffer.numItems)

onPaint = (timestamp) ->
	updateFps timestamp

	# bind framebuffer, clear
	gl.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer)
	gl.viewport(0, 0, frameBuffer.width, frameBuffer.height)
	gl.clearColor(0.0, 0.0, 0.0, 1.0)
	gl.clear( gl.COLOR_BUFFER_BIT, gl.DEPTH_BUFFER_BIT, gl.STENCIL_BUFFER_BIT)

	# render quad to framebuffer
	paintQuadWithShader(primaryShaderProgram)

	# render to screen
	gl.bindFramebuffer(gl.FRAMEBUFFER, null)
	gl.clearColor(0.3, 0.3, 0.3, 1.0)
	gl.viewport(0, 0, gl.viewportWidth, gl.viewportHeight)
	gl.clear( gl.COLOR_BUFFER_BIT, gl.DEPTH_BUFFER_BIT, gl.STENCIL_BUFFER_BIT)

	# Bind textures
	gl.activeTexture(gl.TEXTURE0)
	gl.bindTexture(gl.TEXTURE_2D, frameBuffer.colorTexture)
	gl.uniform1i(secondaryShaderProgram.colorTextureUniform, 0)
	gl.activeTexture(gl.TEXTURE1)
	gl.bindTexture(gl.TEXTURE_2D, frameBuffer.depthTexture)
	gl.uniform1i(secondaryShaderProgram.depthTextureUniform, 1)

	# add stencilbuffer overhead
	gl.enable(gl.STENCIL_TEST)
	gl.stencilFunc(gl.ALWAYS, 0xFF, 0xFF)
	gl.stencilOp(gl.ZERO, gl.REPLACE, gl.REPLACE)
	gl.stencilMask(0xFF)

	# render quad
	paintQuadWithShader(secondaryShaderProgram)

	gl.stencilFunc(gl.EQUAL, 0x00, 0xFF)
	gl.stencilOp(gl.INCR, gl.INCR, gl.KEEP)

	# render quad a second time, just to test stencil buffer
	# comparison overhead
	paintQuadWithShader(secondaryShaderProgram)

	# disable Stencil buffer
	gl.disable(gl.STENCIL_TEST)

	requestAnimationFrame onPaint

gl = initGl()
visibleQuadBuffer = initQuadBuffer(0.8)
primaryShaderProgram = initShaderProgram(
	shaderSources.vertexPrimary,shaderSources.fragmentPrimary
)
secondaryShaderProgram = initShaderProgram(
	shaderSources.vertexPrimary,shaderSources.fragmentSecondary
)
frameBuffer = createFramebuffer(1024, 1024)

window.requestAnimationFrame onPaint
