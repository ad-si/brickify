/*
 * This module estimates the printing time for a THREE.Geometry.
 * @module printingTimeEstimator
 */

const forAllFaces = function (threeGeometry, visitor) {
  const {
    faces,
  } = threeGeometry
  const {
    vertices,
  } = threeGeometry

  return (() => {
    const result = []
    for (const face of Array.from(faces)) {
      const a = vertices[face.a]
      const b = vertices[face.b]
      const c = vertices[face.c]
      result.push(visitor(a, b, c))
    }
    return result
  })()
}

/*
 * # calculates the volume of threeGeometry
 * see http://stackoverflow.com/questions/1410525
 * @param {THREE.Geometry} threeGeometry an instance of three geometry
 * @return {Number} volume in cm^3
 */
const getVolume = function (threeGeometry) {
  let volume = 0
  forAllFaces(threeGeometry, (a, b, c) => volume += ((a.x * b.y * c.z) + (a.y * b.z * c.x) + (a.z * b.x * c.y)) -
    (a.x * b.z * c.y) - (a.y * b.x * c.z) - (a.z * b.y * c.x))
  return volume / 6 / 1000
}


/*
 * calculates the surface area of threeGeometry
 * @param {THREE.Geometry} threeGeometry an instance of three geometry
 * @return {Number} surface in cm^2
 */
const getSurface = function (threeGeometry) {
  let surface = 0
  forAllFaces(threeGeometry, (a, b, c) => {
    const ab = new THREE.Vector3(b.x - a.x, b.y - a.y, b.z - a.z)
    const ac = new THREE.Vector3(c.x - a.x, c.y - a.y, c.z - a.z)
    return surface += ab.cross(ac)
      .length()
  })
  return surface / 2 / 100
}

/*
 * calculates the height of threeGeometry
 * @param {THREE.Geometry} threeGeometry an instance of three geometry
 * @return {Number} height in cm
 */
const getHeight = function (threeGeometry) {
  const {
    vertices,
  } = threeGeometry
  if (vertices.length === 0) {
    return 0
  }

  let minZ = vertices[0].z
  let maxZ = vertices[0].z

  for (const vertex of Array.from(vertices)) {
    minZ = Math.min(vertex.z, minZ)
    maxZ = Math.max(vertex.z, maxZ)
  }

  const height = maxZ - minZ
  return height / 10
}

/*
 * time approximation taken from MakerBot Desktop software configured for
 * Replicator 5th Generation
 * @param {THREE.Geometry} threeGeometry an instance of three geometry
 * @return {Number} approximate printing time in minutes
 */
const getEstimate = function (height, surface, volume) {
  if (volume === 0) {
    return 0
  }
  return 2 + (2 * height) + (0.3 * surface) + (2.5 * volume)
}

module.exports.getPrintingTimeEstimate = function (geometries) {
  let time = 0
  for (const geometry of Array.from(geometries)) {
    const height = getHeight(geometry)
    const surface = getSurface(geometry)
    const volume = getVolume(geometry)

    time += getEstimate(height, surface, volume)
  }

  return time
}

module.exports.getPrintingTimeEstimateForVoxels = function (voxels, gridSpacing) {
  let z
  if (voxels.length === 0) {
    return 0
  }

  let maxZ = voxels[0].position.z
  let minZ = maxZ
  for (const voxel of Array.from(voxels)) {
    ({
      z,
    } = voxel.position)
    maxZ = Math.max(z, maxZ)
    minZ = Math.min(z, minZ)
  }

  const height = (((maxZ - minZ) + 1) * gridSpacing.z) / 10

  let voxelSurface = gridSpacing.x * gridSpacing.z
  voxelSurface += gridSpacing.x * gridSpacing.y
  voxelSurface += gridSpacing.y * gridSpacing.z
  // voxelSurface *= 2
  voxelSurface /= 100
  let surface = voxelSurface * voxels.length // / 2
  // to account for adjacent voxels
  surface /= 2

  let voxelVolume = gridSpacing.x * gridSpacing.y * gridSpacing.z
  voxelVolume /= 1000
  let volume = voxelVolume * voxels.length
  // not all voxels are completely filled
  volume /= 3

  return getEstimate(height, surface, volume)
}
