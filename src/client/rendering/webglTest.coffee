initGl = ->
	canvas = document.getElementById 'glCanvas'
	gl = canvas.getContext('webgl', {stencil: true})

	gl.clearColor(0,0,0,1)
	gl.enable(gl.DEPTH_TEST)
	gl.depthFunc(gl.LEQUAL)
	gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	return gl


gl = initGl()
