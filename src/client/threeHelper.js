import THREE from "three"


export function link (node, threeNode) {
  return threeNode.brickifyNode = node.id
}


export function find (node, threeParentNode) {
  return threeParentNode.getObjectByProperty("brickifyNode", node.id, true)
}


export function applyNodeTransforms (node, threeNode) {
  const _set = (property, vector) => property.set(vector.x, vector.y, vector.z)

  _set(threeNode.position, node.transform.position)
  _set(threeNode.rotation, node.transform.rotation)
  return _set(threeNode.scale, node.transform.scale)
}


export function getTransformMatrix (node) {
  const threeNode = new THREE.Object3D()
  applyNodeTransforms(node, threeNode)
  threeNode.updateMatrix()
  return threeNode.matrix
}


export function getBoundingSphere (threeNode) {
  if (threeNode.geometry != null) {
    const {
      geometry,
    } = threeNode
    geometry.computeBoundingSphere()
    const {
      boundingSphere,
    } = geometry
    threeNode.updateMatrix()
    if (threeNode.parent != null) {
      threeNode.parent.updateMatrixWorld()
    }
    boundingSphere.center.applyProjection(threeNode.matrixWorld)
    return boundingSphere
  }
  else if (threeNode instanceof THREE.Object3D) {
    const boundingBox = new THREE.Box3()
      .setFromObject(threeNode)
    const size = boundingBox.size()
    const radius = Math.sqrt(
      (size.x * size.x) + (size.y * size.y) + (size.z * size.z),
    ) / 2
    const center = boundingBox.center()
    return {radius, center}
  }
}


export function zoomToBoundingSphere (
  camera, scene, controls, boundingSphere) {
  const {
    radius,
  } = boundingSphere
  const {
    center,
  } = boundingSphere

  const alpha = camera.fov
  const distanceToObject = radius / Math.sin(alpha)

  let rv = camera.position.clone()
  if (controls != null) {
    rv.sub(controls.target)
  }
  rv = rv.normalize()
    .multiplyScalar(distanceToObject)
  const zoomAdjustmentFactor = 2.5
  rv = rv.multiplyScalar(zoomAdjustmentFactor)

  // apply scene transforms (e.g. rotation to make y the vector facing upwards)
  const target = center.clone()
    .applyMatrix4(scene.matrix)
  const position = target.clone()
    .add(rv)

  camera.position.set(position.x, position.y, position.z)
  camera.lookAt(target)

  if (controls != null) {
    return controls.set({ target, position })
  }
}
