###
# @module renderer
###

THREE = require 'three'
OrbitControls = require('three-orbit-controls')(THREE)

pluginHooks = require '../common/pluginHooks'
Stats = require 'stats-js'
#TrackballControls = require 'Three.trackball'
#TrackballControls = require('../../../TrackballControls/index.js')(Three)
#OrbitControls = require('three-orbit-controls')(Three)
#OrbitControls = require('../../../OrbitControls/index.js')(Three)

#TrackballControls.prototype = Object.create(Three.EventDispatcher.prototype)
#OrbitControls.prototype = Object.create(Three.EventDispatcher.prototype )


renderer = null
scene = null
camera = null
controls = null
stats = null


localRenderer = (timestamp) ->
	stats?.begin()
	renderer.render scene, camera
	pluginHooks.on3dUpdate timestamp
	stats?.end()

	requestAnimationFrame localRenderer

module.exports.addToScene = (node) ->
	scene.add node

module.exports.getDomElement = () ->
	renderer.domElement

module.exports.windowResizeHandler = () ->
	camera.aspect = window.innerWidth / window.innerHeight
	camera.updateProjectionMatrix()

	renderer.setSize(window.innerWidth, window.innerHeight)
	renderer.render(scene, camera)

module.exports.init = (globalConfig) ->
	setupRenderer globalConfig
	setupScene globalConfig
	setupLighting globalConfig
	setupCamera globalConfig
	setupControls globalConfig
	setupFPSCounter() if process.env.NODE_ENV is 'development'
	requestAnimationFrame localRenderer


setupRenderer = (globalConfig) ->
	renderer = new THREE.WebGLRenderer(
		alpha: true
		antialias: true
		preserveDrawingBuffer: true
	)
	renderer.setSize window.innerWidth, window.innerHeight
	renderer.setClearColor 0xf6f6f6, 1
	renderer.domElement.setAttribute 'id', 'canvas'
	document
	.getElementById('renderArea')
	.appendChild renderer.domElement


setupScene = (globalConfig) ->
	scene = new THREE.Scene()

	# Scene rotation because orbit controls only works
	# with up vector of 0, 1, 0
	sceneRotation = new THREE.Matrix4()
	sceneRotation.makeRotationAxis(
		new THREE.Vector3(1, 0, 0),
		(-Math.PI / 2)
	)
	scene.applyMatrix(sceneRotation)


setupLighting = (globalConfig) ->
	ambientLight = new THREE.AmbientLight(0x404040)
	scene.add(ambientLight)

	directionalLight = new THREE.DirectionalLight(0xffffff)
	directionalLight.position.set 0, 20, 30
	scene.add(directionalLight)

	directionalLight = new THREE.DirectionalLight(0x808080)
	directionalLight.position.set 20, 0, 30
	scene.add(directionalLight)

setupCamera = (globalConfig) ->
	camera = new THREE.PerspectiveCamera(
		globalConfig.fov,
		window.innerWidth / window.innerHeight,
		globalConfig.cameraNearPlane,
		globalConfig.cameraFarPlane
	)
	camera.position.set(
		globalConfig.axisLength
		globalConfig.axisLength + 10
		globalConfig.axisLength / 2
	)
	camera.up.set(0, 1, 0)
	camera.lookAt(new THREE.Vector3(0, 0, 0))

setupControls = (globalConfig) ->
	controls = new OrbitControls(camera, renderer.domElement)
	controls.target.set(0, 0, 0)

setupFPSCounter = () ->
	stats = new Stats()
	# 0 means FPS, 1 means ms per frame
	stats.setMode(0)
	stats.domElement.style.position = 'absolute'
	stats.domElement.style.right = '0px'
	stats.domElement.style.bottom = '0px'
	document.body.appendChild(stats.domElement)
