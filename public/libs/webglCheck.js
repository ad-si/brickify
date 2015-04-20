!function () {

	var gl,
		canvas

	try {
		canvas = document.createElement('canvas')
		gl = canvas.getContext('webgl')
	}
	catch (error) {
		console.error(error)
	}

	if (!gl)
		try {
			gl = canvas.getContext("experimental-webgl")
		}
		catch (error) {
			console.error(error)
		}

	if (!gl){
		warning = document.getElementById('webGlWarning')
		if (warning != null){
			warning.style.display = 'inherit'
		}

		alert("Your browser does not support WebGL. Please use a modern browser like Google Chrome to use this website.")
	}

	gl = null
	canvas = null
}()
