!function () {

	var gl,
		canvas

	try {
		canvas = document.getElementById('canvas')
		console.log(canvas)
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

	if (!gl)
		document
			.getElementById('webGlWarning')
			.style
			.display = 'inherit'
}()
