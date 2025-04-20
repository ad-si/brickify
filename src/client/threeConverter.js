module.exports.toStandardGeometry = function (modelObject) {

  const {
    vertexCoordinates,
    faceVertexIndices,
    faceNormalCoordinates,
  } = modelObject.mesh.faceVertex

  const geometry = new THREE.Geometry()

  for (let vi = 0, end = vertexCoordinates.length - 1; vi <= end; vi += 3) {
    geometry.vertices.push(new THREE.Vector3(
      vertexCoordinates[vi],
      vertexCoordinates[vi + 1],
      vertexCoordinates[vi + 2],
    ),
    )
  }

  for (let fi = 0, end1 = faceVertexIndices.length - 1; fi <= end1; fi += 3) {
    geometry.faces.push(new THREE.Face3(
      faceVertexIndices[fi],
      faceVertexIndices[fi + 1],
      faceVertexIndices[fi + 2],
      new THREE.Vector3(
        faceNormalCoordinates[fi],
        faceNormalCoordinates[fi + 1],
        faceNormalCoordinates[fi + 2],
      ),
    ),
    )
  }

  return geometry
}

module.exports.toBufferGeometry = function (modelObject) {

  let i
  let asc; let end
  let asc1; let end1
  let asc2; let end2
  const {
    vertexCoordinates,
    faceVertexIndices,
    vertexNormalCoordinates,
  } = modelObject.mesh.faceVertex

  const geometry = new THREE.BufferGeometry()

  // Three offcially supports normal arrays, but you actually
  // have to use this lowlevel datatype to view anything
  const parray = new Float32Array(vertexCoordinates.length)
  for (i = 0, end = vertexCoordinates.length - 1, asc = end >= 0; asc ? i <= end : i >= end; asc ? i++ : i--) {
    parray[i] = vertexCoordinates[i]
  }

  const narray = new Float32Array(vertexNormalCoordinates.length)
  for (i = 0, end1 = vertexNormalCoordinates.length - 1, asc1 = end1 >= 0; asc1 ? i <= end1 : i >= end1; asc1 ? i++ : i--) {
    narray[i] = vertexNormalCoordinates[i]
  }

  const iarray = new Uint32Array(faceVertexIndices.length)
  for (i = 0, end2 = faceVertexIndices.length - 1, asc2 = end2 >= 0; asc2 ? i <= end2 : i >= end2; asc2 ? i++ : i--) {
    iarray[i] = faceVertexIndices[i]
  }

  geometry.addAttribute("index", new THREE.BufferAttribute(iarray, 1))
  geometry.addAttribute("position", new THREE.BufferAttribute(parray, 3))
  geometry.addAttribute("normal", new THREE.BufferAttribute(narray, 3))
  geometry.computeBoundingSphere()

  return geometry
}


module.exports.threeGeometryToFaceVertexMesh = function (threeGeometry) {

  let index; let offset
  const faceVertexMesh = {
    vertexCoordinates: new Array(threeGeometry.vertices.length * 3),
    faceVertexIndices: new Array(threeGeometry.faces.length * 3),
    faceNormalCoordinates: new Array(threeGeometry.faces.length * 3),
  }

  for (index = 0; index < threeGeometry.vertices.length; index++) {
    const vertex = threeGeometry.vertices[index]
    offset = index * 3
    faceVertexMesh.vertexCoordinates[offset] = vertex.x
    faceVertexMesh.vertexCoordinates[offset + 1] = vertex.y
    faceVertexMesh.vertexCoordinates[offset + 2] = vertex.z
  }

  for (index = 0; index < threeGeometry.faces.length; index++) {
    const face = threeGeometry.faces[index]
    offset = index * 3
    faceVertexMesh.faceVertexIndices[offset] = face.a
    faceVertexMesh.faceVertexIndices[offset + 1] = face.b
    faceVertexMesh.faceVertexIndices[offset + 2] = face.c

    faceVertexMesh.faceNormalCoordinates[offset] = face.normal.x
    faceVertexMesh.faceNormalCoordinates[offset + 1] = face.normal.y
    faceVertexMesh.faceNormalCoordinates[offset + 2] = face.normal.z
  }

  return faceVertexMesh
}
