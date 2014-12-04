###
  # Axis constructor

  Creates colored axis inside a threejs node with a provided global config
###

THREE = require 'three'

module.exports = (threejsNode, globalConfig) ->
	# **Create and add x-axis**
	geometryXAxis = new THREE.Geometry()
	geometryXAxis.vertices.push(
		new THREE.Vector3(0, 0, 0)
	)
	geometryXAxis.vertices.push(
		new THREE.Vector3( globalConfig.axisLength, 0, 0)
	)
	materialXAxis = new THREE.LineBasicMaterial(
		color: globalConfig.axisXColor
		linewidth: globalConfig.axisLineWidth
	)
	xAxis = new THREE.Line(geometryXAxis, materialXAxis)
	threejsNode.add(xAxis)

	# **Create and add y-axis**
	geometryYAxis = new THREE.Geometry()
	geometryYAxis.vertices.push(
		new THREE.Vector3( 0,0, 0)
	)
	geometryYAxis.vertices.push(
		new THREE.Vector3( 0, globalConfig.axisLength, 0)
	)
	materialYAxis = new THREE.LineBasicMaterial(
		color: globalConfig.axisYColor
		linewidth: globalConfig.axisLineWidth
	)
	yAxis = new THREE.Line(geometryYAxis, materialYAxis)
	threejsNode.add(yAxis)

	# **Create and add z-axis**
	geometryZAxis = new THREE.Geometry()
	geometryZAxis.vertices.push(
		new THREE.Vector3( 0, 0, 0)
	)
	geometryZAxis.vertices.push(
		new THREE.Vector3( 0, 0, globalConfig.axisLength)
	)
	materialZAxis = new THREE.LineBasicMaterial(
		color: globalConfig.axisZColor
		linewidth: globalConfig.axisLineWidth
	)
	zAxis = new THREE.Line(geometryZAxis, materialZAxis)
	threejsNode.add(zAxis)
