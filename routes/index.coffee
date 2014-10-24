module.exports = (request, response) ->
	response.render 'index', {
		scripts: {
			jquery: 'libs/jquery/dist/jquery.js',
			threejs: 'libs/threejs/build/three.js',
			STLLoader: 'libs/STLLoader/index.js',
			TrackballControls: 'libs/TrackballControls/index.js',
			OrbitControls: 'libs/OrbitControls/index.js',
			index: 'index.js'
		}
	}
