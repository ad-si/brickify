/*
  * Axis constructor

  Creates colored axis inside a threejs node with a provided global config
*/

import THREE, { type Object3D } from "three"

interface AxisConfig {
  axisLength: number;
  axisLineWidth: number;
  colors: {
    axisX: number;
    axisY: number;
    axisZ: number;
  };
}

export default function (threejsNode: Object3D, globalConfig: AxisConfig) {
  // **Create and add x-axis**
  const geometryXAxis = new THREE.Geometry()
  geometryXAxis.vertices.push(
    new THREE.Vector3(0, 0, 0),
  )
  geometryXAxis.vertices.push(
    new THREE.Vector3(globalConfig.axisLength, 0, 0),
  )
  const materialXAxis = new THREE.LineBasicMaterial({
    color: globalConfig.colors.axisX,
    linewidth: globalConfig.axisLineWidth,
  })
  const xAxis = new THREE.Line(geometryXAxis, materialXAxis)
  threejsNode.add(xAxis)

  // **Create and add y-axis**
  const geometryYAxis = new THREE.Geometry()
  geometryYAxis.vertices.push(
    new THREE.Vector3(0, 0, 0),
  )
  geometryYAxis.vertices.push(
    new THREE.Vector3(0, globalConfig.axisLength, 0),
  )
  const materialYAxis = new THREE.LineBasicMaterial({
    color: globalConfig.colors.axisY,
    linewidth: globalConfig.axisLineWidth,
  })
  const yAxis = new THREE.Line(geometryYAxis, materialYAxis)
  threejsNode.add(yAxis)

  // **Create and add z-axis**
  const geometryZAxis = new THREE.Geometry()
  geometryZAxis.vertices.push(
    new THREE.Vector3(0, 0, 0),
  )
  geometryZAxis.vertices.push(
    new THREE.Vector3(0, 0, globalConfig.axisLength),
  )
  const materialZAxis = new THREE.LineBasicMaterial({
    color: globalConfig.colors.axisZ,
    linewidth: globalConfig.axisLineWidth,
  })
  const zAxis = new THREE.Line(geometryZAxis, materialZAxis)
  return threejsNode.add(zAxis)
}
