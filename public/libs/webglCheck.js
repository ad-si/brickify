!function () {

	var gl,
		canvas

	var webglWarned = false
	var webglWarning = function () {
		if (!webglWarned) {
			alert("Your browser does not support WebGL. Please use a modern browser like Google Chrome to use this website.")
		}
		webglWarned = true
	}

	try {
		canvas = document.getElementById('canvas')
		gl = canvas.getContext('webgl')
	}
	catch (error) {
		console.error(error)
		webglWarning()
	}

	if (!gl)
		try {
			gl = canvas.getContext("experimental-webgl")
		}
		catch (error) {
			console.error(error)
			webglWarning()
		}

	if (!gl)
		document
			.getElementById('webGlWarning')
			.style
			.display = 'inherit'
		webglWarning()
}()
