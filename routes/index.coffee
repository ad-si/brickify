module.exports = (request, response) ->
	response.render 'index',
		scripts:
			jquery: 'libs/jquery/dist/jquery.js'
			threejs: 'libs/threejs/build/three.js'
			bootstrap: 'libs/bootstrap/dist/js/bootstrap.js'
			STLLoader: 'libs/STLLoader/index.js'
			TrackballControls: 'libs/TrackballControls/index.js'
			OrbitControls: 'libs/OrbitControls/index.js'
			index: 'index.js'
		styles:
			bootstrap: 'libs/bootstrap/dist/css/bootstrap.css'
			index: 'styles/screen.css'
