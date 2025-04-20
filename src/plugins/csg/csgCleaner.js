import log from "loglevel"

const clean = function (geometry, options) {
  let d; let geometries
  if (options == null) {
    options = {}
  }
  if (!geometry) {
    return []
  }

  if (options.split) {
    d = new Date()
    geometries = splitGeometry(geometry)
    log.debug(`Model splitting took ${new Date() - d}ms`)
  }
  else {
    log.debug("(Skipping step model splitting)")
    geometries = [geometry]
  }

  if (options.filterSmallGeometries) {
    d = new Date()
    geometries = filterSmallGeometries(geometries, options.minimalPrintVolume)
    log.debug(`Filtering small geometries took ${new Date() - d}ms`)
  }
  else {
    log.debug("(Skipping step filtering small geometries)")
  }

  return geometries
}

var filterSmallGeometries = function (geometries, minimalPrintVolume) {
  const filteredGeometries = []
  for (const geometry of Array.from(geometries)) {
    const volume = getVolume(geometry)
    if (volume > minimalPrintVolume) {
      filteredGeometries.push(geometry)
    }
  }
  return filteredGeometries
}

/*
 * calculates the volume of threeGeometry
 * see http://stackoverflow.com/questions/1410525
 * @param {THREE.Geometry} threeGeometry an instance of three geometry
 * @return {Number} volume in mm^3
 */
var getVolume = function (threeGeometry) {
  let volume = 0
  forAllFaces(threeGeometry, (a, b, c) => volume += ((a.x * b.y * c.z) + (a.y * b.z * c.x) + (a.z * b.x * c.y)) -
      (a.x * b.z * c.y) - (a.y * b.x * c.z) - (a.z * b.y * c.x))
  return volume / 6
}

var forAllFaces = function (threeGeometry, visitor) {
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

var splitGeometry = function (geometry) {
  geometry.mergeVertices()
  const connectedComponents = getConnectedComponents(geometry)
  if (connectedComponents.length === 1) {
    return [geometry]
  }

  const geometries = []
  for (const component of Array.from(connectedComponents)) {
    geometries.push(buildGeometry(component, geometry))
  }

  return geometries
}

var buildGeometry = function (hashmap, baseGeometry) {
  const geometry = new THREE.Geometry()
  hashmap.faceIndices.forEach((faceIndex) => {
    const face = baseGeometry.faces[faceIndex]
    const {
      length,
    } = geometry.vertices
    geometry.vertices.push(
      baseGeometry.vertices[face.a],
      baseGeometry.vertices[face.b],
      baseGeometry.vertices[face.c],
    )
    return geometry.faces.push(
      new THREE.Face3(length, length + 1, length + 2, face.normal),
    )
  })

  geometry.mergeVertices()
  geometry.verticesNeedUpdate = true
  geometry.elementsNeedUpdate = true

  return geometry
}

var getConnectedComponents = function (geometry) {
  let equivalenceClasses = []

  if (geometry.faces.length === 0) {
    return equivalenceClasses
  }

  for (let i = 0, end = geometry.faces.length - 1, asc = end >= 0; asc ? i <= end : i >= end; asc ? i++ : i--) {
    var equivalenceClass
    const face = geometry.faces[i]
    const {
      a,
    } = face
    const {
      b,
    } = face
    const {
      c,
    } = face
    const connectedClasses = []

    for (equivalenceClass of Array.from(equivalenceClasses)) {
      if (equivalenceClass.vertexIndices.has(a) ||
      equivalenceClass.vertexIndices.has(b) ||
      equivalenceClass.vertexIndices.has(c)) {
        equivalenceClass.vertexIndices.add(a)
        equivalenceClass.vertexIndices.add(b)
        equivalenceClass.vertexIndices.add(c)
        equivalenceClass.faceIndices.add(i)
        connectedClasses.push(equivalenceClass)
      }
    }

    if (connectedClasses.length === 0) {
      equivalenceClass = {
        vertexIndices: new Set(),
        faceIndices: new Set(),
      }
      equivalenceClass.vertexIndices.add(a)
      equivalenceClass.vertexIndices.add(b)
      equivalenceClass.vertexIndices.add(c)
      equivalenceClass.faceIndices.add(i)
      equivalenceClasses.push(equivalenceClass)

    }
    else if (connectedClasses.length > 1) {
      compactClasses(connectedClasses)
      equivalenceClasses = equivalenceClasses.filter(a => a.faceIndices.size > 0)
    }
  }

  return equivalenceClasses
}

var compactClasses = function (equivalenceClasses) {
  const {
    vertexIndices,
  } = equivalenceClasses[0]
  const {
    faceIndices,
  } = equivalenceClasses[0]

  return (() => {
    const result = []
    for (let i = 1, end = equivalenceClasses.length - 1; i <= end; i++) {
      const equivalenceClass = equivalenceClasses[i]
      equivalenceClass.vertexIndices.forEach(vertex => vertexIndices.add(vertex))
      equivalenceClass.faceIndices.forEach(faceIndex => faceIndices.add(faceIndex))

      // clear old class
      equivalenceClass.vertexIndices.clear()
      result.push(equivalenceClass.faceIndices.clear())
    }
    return result
  })()
}

module.exports.clean = clean
