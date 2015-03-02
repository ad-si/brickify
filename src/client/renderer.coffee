THREE = require 'three'
OrbitControls = require('three-orbit-controls')(THREE)
Stats = require 'stats-js'

###
# @class Renderer
###
module.exports = class Renderer
	constructor: (@pluginHooks, globalConfig, controls) ->
		@scene = null
		@camera = null
		@threeRenderer = null
		@init globalConfig, controls

	localRenderer: (timestamp) =>
			@stats?.begin()
			@threeRenderer.render @.scene, @.camera
			@pluginHooks.on3dUpdate timestamp
			@controls.update()

			@stats?.end()
			requestAnimationFrame @localRenderer

	onStateUpdate: (state) =>
		for r in @pluginHooks.newBoundingSphere()
			@adjustCameraToObject r if r?

	addToScene: (node) ->
		@scene.add node

	getDomElement: () ->
		return @threeRenderer.domElement

	getCamera: () ->
		return @camera

	windowResizeHandler: () ->
		if not @staticRendererSize
			@camera.aspect = @size().width / @size().height
			@camera.updateProjectionMatrix()
			@threeRenderer.setSize @size().width, @size().height

		@threeRenderer.render @scene, @camera

	adjustCameraToObject: (radiusAndPosition) ->
		# zooms out/in the camera so that the object is fully visible
		radius = radiusAndPosition.radius
		center = radiusAndPosition.center
		center = new THREE.Vector3(center.x, center.y, center.z)

		alpha = @camera.fov
		distanceToObject = radius / Math.sin(alpha)

		rv = @camera.position.clone().sub(@controls.target)
		rv = rv.normalize().multiplyScalar(distanceToObject)
		zoomAdjustmentFactor = 2.5
		rv = rv.multiplyScalar(zoomAdjustmentFactor)

		#apply scene transforms (e.g. rotation to make y the vector facing upwards)
		target = center.clone().applyMatrix4(@scene.matrix)
		position = target.clone().add(rv)
		@setCamera position, target

	setCamera: (position, target) ->
		@controls.update()
		@controls.target = @controls.target0 =
			new THREE.Vector3(target.x, target.y, target.z)
		@controls.position = @controls.position0 =
			new THREE.Vector3(position.x, position.y, position.z)
		@controls.reset()

	init: (globalConfig, controls) ->
		@setupSize globalConfig
		@setupRenderer globalConfig
		@setupScene globalConfig
		@setupLighting globalConfig
		@setupCamera globalConfig
		@setupControls globalConfig, controls
		@setupFPSCounter() if process.env.NODE_ENV is 'development'
		requestAnimationFrame @localRenderer

	setupSize: (globalConfig) ->
		if not globalConfig.staticRendererSize
			@staticRendererSize = false
		else
			@staticRendererSize = true
			@staticRendererWidth = globalConfig.staticRendererWidth
			@staticRendererHeight = globalConfig.staticRendererHeight

	size: ->
		if @staticRendererSize
			return {width: @staticRendererWidth, height: @staticRendererHeight}
		else
			return {width: window.innerWidth, height: window.innerHeight}

	setupRenderer: (globalConfig) ->
		@threeRenderer = new THREE.WebGLRenderer(
			alpha: true
			antialias: true
			preserveDrawingBuffer: true
			canvas: document.getElementById globalConfig.renderAreaId
		)

		@threeRenderer.setSize @size().width, @size().height


	setupScene: (globalConfig) ->
		@scene = new THREE.Scene()
		# Scene rotation because orbit controls only works
		# with up vector of 0, 1, 0
		sceneRotation = new THREE.Matrix4()
		sceneRotation.makeRotationAxis(
			new THREE.Vector3( 1, 0, 0 ),
			(-Math.PI / 2)
		)
		@scene.applyMatrix(sceneRotation)
		@scene.fog = new THREE.Fog(
			globalConfig.colors.background
			globalConfig.cameraNearPlane
			globalConfig.cameraFarPlane
		)

	setupCamera: (globalConfig) ->
		@camera = new THREE.PerspectiveCamera(
			globalConfig.fov,
			(@size().width / @size().height),
			globalConfig.cameraNearPlane,
			globalConfig.cameraFarPlane
		)
		@camera.position.set(
			globalConfig.axisLength
			globalConfig.axisLength + 10
			globalConfig.axisLength / 2
		)
		@camera.up.set(0, 1, 0)
		@camera.lookAt(new THREE.Vector3(0, 0, 0))

	setupControls: (globalConfig, controls) ->
		if controls?
			controls.addObject @camera
			controls.addDomElement @threeRenderer.domElement
			controls.update()
			@controls = controls
		else
			@controls = new OrbitControls(@camera, @threeRenderer.domElement)
			@controls.autoRotate = globalConfig.autoRotate
			@controls.autoRotateSpeed = globalConfig.autoRotateSpeed
			@controls.target.set(0, 0, 0)

	setupFPSCounter: () ->
		@stats = new Stats()
		# 0 means FPS, 1 means ms per frame
		@stats.setMode(0)
		@stats.domElement.style.position = 'absolute'
		@stats.domElement.style.right = '0px'
		@stats.domElement.style.bottom = '0px'
		document.body.appendChild(@stats.domElement)

	setupLighting: (globalConfig) ->
		ambientLight = new THREE.AmbientLight(0x404040)
		@scene.add ambientLight

		directionalLight = new THREE.DirectionalLight(0xffffff)
		directionalLight.position.set 0, 20, 30
		@scene.add directionalLight

		directionalLight = new THREE.DirectionalLight(0x808080)
		directionalLight.position.set 20, 0, 30
		@scene.add directionalLight

		directionalLight = new THREE.DirectionalLight(0x808080)
		directionalLight.position.set 20, -20, -30
		@scene.add directionalLight

	###
	# Calculates the position on the z=0 plane in 3d space from given screen
  # (mouse) coordinates.
  #
  # @param {Number} screenX the x coordinate of the mouse event
  # @param {Number} screenY the y coordinate of the mouse event
  # @memberOf Renderer
	###
	getGridPosition: (screenX, screenY) ->
		canvas = @threeRenderer.context.canvas

		posInCanvas = new THREE.Vector3(
			(screenX / canvas.width) * 2 - 1
			(-screenY / canvas.height) * 2 + 1
			0.5
		)

		posInCamera = posInCanvas.clone().unproject @camera

		ray = posInCamera.sub(@camera.position).normalize()
		# we are calculating in camera coordinate system -> y and z are rotated
		ray.multiplyScalar -@camera.position.y / ray.y
		posInWorld = @camera.position.clone().add ray

		posInScene = new THREE.Vector3 posInWorld.x, -posInWorld.z, posInWorld.y
		return posInScene

	loadCamera: (state) =>
		if state.controls?
			@setCamera state.controls.position, state.controls.target

	saveCamera: (state) =>
		p = @camera.position
		t = @controls.target
		state.controls = {
			position: { x: p.x, y: p.y, z: p.z }
			target: { x: t.x, y: t.y, z: t.z }
		}

	getControls: () =>
		@controls
