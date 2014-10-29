statesync = require './statesync'
objectTree = require '../common/objectTree'

module.exports = (globalConfig) ->
	return {
		# setup scene
		scene: new THREE.Scene()
		camera: new THREE.PerspectiveCamera(
			globalConfig.fov,
			window.innerWidth / window.innerHeight,
			globalConfig.cameraNearPlane,
			globalConfig.cameraFarPlane
		)
		renderer: new THREE.WebGLRenderer(
			alpha: true
			antialiasing: true
			preserveDrawingBuffer: true
		)
		controls: null
		stlLoader: new THREE.STLLoader()
		fileReader: new FileReader()

		keyUpHandler: ( event ) ->
			if event.keyCode == 67
				for mesh in globalConfig.meshes
					@scene.remove mesh
				globalConfig.meshes = []

		# overwrite if in your code neccessary
		loadHandler: ( event ) ->
			geometry = @stlLoader.parse( event.target.result )
			$(@).trigger( 'geometry-loaded', geometry )

			objectMaterial = new THREE.MeshLambertMaterial(
				{
					color: globalConfig.defaultObjectColor
					ambient: globalConfig.defaultObjectColor
				}
			)
			object = new THREE.Mesh( geometry, objectMaterial )
			@scene.add( object )

			md5hash = md5(event.target.result)
			fileEnding = 'stl'

			statesync.performStateAction (state) ->
				state.rootNode.modelLink = md5hash + '.' + fileEnding

			$.get('/model/exists/' + md5hash + '/' + fileEnding).fail () ->
				#server hasn't got the model, send it
				$.ajax '/model/submit/' + md5hash + '/' + fileEnding,
					data: event.target.result
					type: 'POST'
					contentType: 'application/octet-stream'
					success: () ->
						console.log 'sent model to the server'
					error: () ->
						console.log 'unable to send model to the server'




		dropHandler: ( event ) ->
			event.stopPropagation()
			event.preventDefault()
			files = event.target.files ? event.dataTransfer.files
			for file in files
				if file.name.search( '.stl' ) >= 0
					@fileReader.readAsBinaryString( file )


		dragOverHandler: ( event ) ->
			event.stopPropagation()
			event.preventDefault()
			event.dataTransfer.dropEffect = 'copy'

		# Bound to updates to the window size:
		# Called whenever the window is resized.
		# It updates the scene settings (@camera and @renderer)
		windowResizeHandler: ( event ) ->
			@camera.aspect = window.innerWidth / window.innerHeight
			@camera.updateProjectionMatrix()

			@renderer.setSize( window.innerWidth, window.innerHeight )
			@renderer.render(@scene, @camera)

		#Creates a grid, but leaves spaces for the coordinate system
		setupGrid: ->
			materialGridNormal = new THREE.LineBasicMaterial(
				color: globalConfig.gridColorNormal
				linewidth: globalConfig.gridLineWidthNormal
			)
			materialGrid5 = new THREE.LineBasicMaterial(
				color: globalConfig.gridColor5
				linewidth: globalConfig.gridLineWidth5
			)
			materialGrid10 = new THREE.LineBasicMaterial(
				color: globalConfig.gridColor10
				linewidth: globalConfig.gridLineWidth10
			)

			#Grids that are not on the X or Y axis
			for i in [1..globalConfig.gridSize/globalConfig.gridStepSize]
				num = i*globalConfig.gridStepSize
				if i % 10*globalConfig.gridStepSize == 0
					material = materialGrid10
				else if i % 5*globalConfig.gridStepSize == 0
					material = materialGrid5
				else
					material = materialGridNormal

				gridLineGeometryXPositive = new THREE.Geometry()
				gridLineGeometryYPositive = new THREE.Geometry()
				gridLineGeometryXNegative = new THREE.Geometry()
				gridLineGeometryYNegative = new THREE.Geometry()

				gridLineGeometryXPositive.vertices.push(
					new THREE.Vector3(-globalConfig.gridSize, num, 0)
				)
				gridLineGeometryXPositive.vertices.push(
					new THREE.Vector3(globalConfig.gridSize, num, 0)
				)
				gridLineGeometryYPositive.vertices.push(
					new THREE.Vector3(num, -globalConfig.gridSize, 0)
				)
				gridLineGeometryYPositive.vertices.push(
					new THREE.Vector3(num,  globalConfig.gridSize, 0)
				)

				gridLineGeometryXNegative.vertices.push(
					new THREE.Vector3(-globalConfig.gridSize, -num, 0)
				)
				gridLineGeometryXNegative.vertices.push(
					new THREE.Vector3(globalConfig.gridSize, -num, 0)
				)
				gridLineGeometryYNegative.vertices.push(
					new THREE.Vector3(-num, -globalConfig.gridSize, 0)
				)
				gridLineGeometryYNegative.vertices.push(
					new THREE.Vector3( -num,  globalConfig.gridSize, 0)
				)

				gridLineXPositive = new THREE.Line(
					gridLineGeometryXPositive,
					material
				)
				gridLineYPositive = new THREE.Line(
					gridLineGeometryYPositive,
					material
				)
				gridLineXNegative = new THREE.Line(
					gridLineGeometryXNegative,
					material
				)
				gridLineYNegative = new THREE.Line(
					gridLineGeometryYNegative,
					material
				)

				@scene.add( gridLineXPositive )
				@scene.add( gridLineYPositive )
				@scene.add( gridLineXNegative )
				@scene.add( gridLineYNegative )

			# Grid lines that are on the X and Y axis
			# make half as big to prevent z-fighting with colored axis indicators
			material = materialGrid10

			gridLineGeometryXPositive = new THREE.Geometry()
			gridLineGeometryYPositive = new THREE.Geometry()
			gridLineGeometryXNegative = new THREE.Geometry()
			gridLineGeometryYNegative = new THREE.Geometry()

			gridLineGeometryXNegative.vertices.push(
				new THREE.Vector3( -globalConfig.gridSize, 0, 0)
			)
			gridLineGeometryXNegative.vertices.push(
				new THREE.Vector3(  0, 0, 0))
			gridLineGeometryYNegative.vertices.push(
				new THREE.Vector3(  0, -globalConfig.gridSize, 0)
			)
			gridLineGeometryYNegative.vertices.push(
				new THREE.Vector3(  0,  0, 0)
			)
			gridLineGeometryXPositive.vertices.push(
				new THREE.Vector3( globalConfig.gridSize/2, 0, 0)
			)
			gridLineGeometryXPositive.vertices.push(
				new THREE.Vector3(  globalConfig.gridSize, 0, 0)
			)
			gridLineGeometryYPositive.vertices.push(
				new THREE.Vector3( 0, globalConfig.gridSize/2, 0)
			)
			gridLineGeometryYPositive.vertices.push(
				new THREE.Vector3( 0,  globalConfig.gridSize, 0)
			)

			gridLineXPositive = new THREE.Line(
				gridLineGeometryXPositive, material
			)
			gridLineYPositive = new THREE.Line(
				gridLineGeometryYPositive, material
			)
			gridLineXNegative = new THREE.Line(
				gridLineGeometryXNegative, material
			)
			gridLineYNegative = new THREE.Line(
				gridLineGeometryYNegative, material
			)

			@scene.add( gridLineXPositive )
			@scene.add( gridLineYPositive )
			@scene.add( gridLineXNegative )
			@scene.add( gridLineYNegative )

		#Creates colored axis indicators
		setupCoordinateSystem: ->
			materialXAxis = new THREE.LineBasicMaterial(
				color: globalConfig.axisXColor
				linewidth: globalConfig.axisLineWidth
			)
			materialYAxis = new THREE.LineBasicMaterial(
				color: globalConfig.axisYColor
				linewidth: globalConfig.axisLineWidth
			)
			materialZAxis = new THREE.LineBasicMaterial(
				color: globalConfig.axisZColor,
				linewidth: globalConfig.axisLineWidth
			)

			geometryXAxis = new THREE.Geometry()
			geometryYAxis = new THREE.Geometry()
			geometryZAxis = new THREE.Geometry()

			geometryXAxis.vertices.push(
				new THREE.Vector3(0, 0, 0)
			)
			geometryXAxis.vertices.push(
				new THREE.Vector3( globalConfig.axisLength, 0, 0)
			)
			geometryYAxis.vertices.push(
				new THREE.Vector3( 0,0, 0)
			)
			geometryYAxis.vertices.push(
				new THREE.Vector3( 0, globalConfig.axisLength, 0)
			)
			geometryZAxis.vertices.push(
				new THREE.Vector3( 0, 0, 0)
			)
			geometryZAxis.vertices.push(
				new THREE.Vector3( 0, 0, globalConfig.axisLength)
			)

			xAxis = new THREE.Line(geometryXAxis, materialXAxis)
			yAxis = new THREE.Line(geometryYAxis, materialYAxis)
			zAxis = new THREE.Line(geometryZAxis, materialZAxis)

			@scene.add(xAxis)
			@scene.add(yAxis)
			@scene.add(zAxis)

		init: ->
			# setup renderer
			@renderer.setSize( window.innerWidth, window.innerHeight )
			@renderer.setClearColor( 0xf6f6f6, 1)
			document.body.appendChild( @renderer.domElement )

			# Scene rotation because orbit controls only works
			# with up vector of 0, 1, 0
			sceneRotation = new THREE.Matrix4()
			sceneRotation.makeRotationAxis(
				new THREE.Vector3( 1, 0, 0 ),
				(-Math.PI/2)
			)
			@scene.applyMatrix(sceneRotation)


			# setup camera
			@camera.position.set(
				globalConfig.axisLength
				globalConfig.axisLength+10
				globalConfig.axisLength/2
			)
			@camera.up.set(0, 1, 0)
			@camera.lookAt(new THREE.Vector3(0, 0, 0))

			@controls = new THREE.OrbitControls(@camera, @renderer.domElement)
			@controls.target.set(0, 0, 0)

			@setupCoordinateSystem()
			@setupGrid()

			# event listener
			@renderer.domElement.addEventListener(
				'dragover'
				@dragOverHandler.bind( @ )
				false
			)
			@renderer.domElement.addEventListener(
				'drop'
				@dropHandler.bind( @ )
				false
			)
			@fileReader.addEventListener(
				'loadend',
				@loadHandler.bind( @ ),
				false
			)
			document.addEventListener(
				'keyup',
				@keyUpHandler.bind( @ )
			)
			window.addEventListener(
				'resize',
				@windowResizeHandler.bind( @ ),
				false
			)

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
