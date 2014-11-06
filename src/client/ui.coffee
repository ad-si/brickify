statesync = require './statesync'
objectTree = require '../common/objectTree'

module.exports = (globalConfig) ->

	fileReader = new FileReader()

	return {
		# setup scene
		scene: new THREE.Scene()
		camera: new THREE.PerspectiveCamera(
			globalConfig.fov
			window.innerWidth / window.innerHeight
			globalConfig.cameraNearPlane
			globalConfig.cameraFarPlane
		)
		renderer: new THREE.WebGLRenderer(
			alpha: true
			antialiasing: true
			preserveDrawingBuffer: true
		)
		fileReader: fileReader
		controls: null
		stlLoader: new THREE.STLLoader()
		keyUpHandler: (event) ->
			if event.keyCode == 67
				for mesh in globalConfig.meshes
					@scene.remove mesh
				globalConfig.meshes = []

		dropHandler: (event) ->
			event.stopPropagation()
			event.preventDefault()
			files = event.target.files ? event.dataTransfer.files
			for file in files
				if file.name.search( '.stl' ) >= 0
					fileReader.readAsBinaryString( file )

		dragOverHandler: (event) ->
			event.stopPropagation()
			event.preventDefault()
			event.dataTransfer.dropEffect = 'copy'

		# Bound to updates to the window size:
		# Called whenever the window is resized.
		# It updates the scene settings (@camera and @renderer)
		windowResizeHandler: () ->
			@camera.aspect = window.innerWidth / window.innerHeight
			@camera.updateProjectionMatrix()

			@renderer.setSize window.innerWidth, window.innerHeight
			@renderer.render @scene, @camera

		init: ->
			# setup renderer
			@renderer.setSize window.innerWidth, window.innerHeight
			@renderer.setClearColor 0xf6f6f6, 1
			document.body.appendChild @renderer.domElement

			# Scene rotation because orbit controls only works
			# with up vector of 0, 1, 0
			sceneRotation = new THREE.Matrix4()
			sceneRotation.makeRotationAxis(
				new THREE.Vector3 1, 0, 0
				-Math.PI/2
			)
			@scene.applyMatrix sceneRotation


			# setup camera
			@camera.position.set(
				globalConfig.axisLength
				globalConfig.axisLength+10
				globalConfig.axisLength/2
			)
			@camera.up.set(0, 1, 0)
			@camera.lookAt new THREE.Vector3 0, 0, 0

			@controls = new THREE.OrbitControls @camera, @renderer.domElement
			@controls.target.set 0, 0, 0

			# event listener
			@renderer.domElement.addEventListener 'dragover', @dragOverHandler
			@renderer.domElement.addEventListener 'drop', @dropHandler
			document.addEventListener 'keyup', @keyUpHandler
			window.addEventListener 'resize', @windowResizeHandler

			# lightning
			ambientLight = new THREE.AmbientLight(0x404040)
			@scene.add(ambientLight)

			directionalLight = new THREE.DirectionalLight(0xffffff)
			directionalLight.position.set 0, 20, 30
			@scene.add(directionalLight)

			directionalLight = new THREE.DirectionalLight(0x808080)
			directionalLight.position.set 20, 0, 30
			@scene.add( directionalLight )
	}
