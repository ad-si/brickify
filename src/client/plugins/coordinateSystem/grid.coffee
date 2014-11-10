###
  #Grid constructor#

  Creates a grid inside a threejs node with a provided global config,
  but leaves spaces for the coordinate system
###
module.exports = (threejsNode, globalConfig) ->
	setupMaterials(globalConfig)
	axisLines(threejsNode, globalConfig)
	otherLines(threejsNode, globalConfig)

###
  **Setup Materials**

  Every 5<sup>th</sup> and 10<sup>th</sup> line is thicker than the others.
###
setupMaterials = (globalConfig) ->
	@materialGridNormal = new THREE.LineBasicMaterial(
		color: globalConfig.gridColorNormal
		linewidth: globalConfig.gridLineWidthNormal
	)
	@materialGrid5 = new THREE.LineBasicMaterial(
		color: globalConfig.gridColor5
		linewidth: globalConfig.gridLineWidth5
	)
	@materialGrid10 = new THREE.LineBasicMaterial(
		color: globalConfig.gridColor10
		linewidth: globalConfig.gridLineWidth10
	)

###
  **Axis grid lines**

  Construct grid lines that are on the X and Y axis<br>
  Make half as big to prevent z-fighting with colored axis indicators
###
axisLines = (threejsNode, globalConfig) ->
	material = @materialGrid10
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
	threejsNode.add( gridLineXPositive )
	threejsNode.add( gridLineYPositive )
	threejsNode.add( gridLineXNegative )
	threejsNode.add( gridLineYNegative )

###
  **Other grid lines**

  Construct grid lines that are not on the X or Y axis
###
otherLines = (threejsNode, globalConfig) ->
	for i in [1..globalConfig.gridSize/globalConfig.gridStepSize]
		num = i*globalConfig.gridStepSize
		if i % 10 == 0
			material = @materialGrid10
		else if i % 5 == 0
			material = @materialGrid5
		else
			material = @materialGridNormal
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
		threejsNode.add( gridLineXPositive )
		threejsNode.add( gridLineYPositive )
		threejsNode.add( gridLineXNegative )
		threejsNode.add( gridLineYNegative )
