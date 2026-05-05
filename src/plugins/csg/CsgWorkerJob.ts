import THREE from "three"

import CsgExtractor from "./CsgExtractor.js"
import clean from "./csgCleaner.js"
import type ThreeBSP from "./ThreeCSG.js"

export interface SerializedFaceVertexMesh {
  vertexCoordinates: number[]
  faceVertexIndices: number[]
  faceNormalCoordinates?: number[]
}

export interface SerializedVoxel {
  x: number
  y: number
  z: number
  enabled: boolean
}

export interface CsgJobInput {
  model: SerializedFaceVertexMesh
  grid: {
    spacing: { x: number; y: number; z: number }
    origin: { x: number; y: number; z: number }
    voxels: SerializedVoxel[]
  }
  options: {
    addStuds?: boolean
    studSize?: { radius: number; height: number }
    holeSize?: { radius: number; height: number }
    minimalPrintVolume?: number
  }
  cacheKey?: string
}

export interface CsgJobResult {
  geometries: SerializedFaceVertexMesh[]
  isOriginalModel: boolean
  everythingBricks: boolean
}

interface VoxelLike {
  enabled: boolean
  position: { x: number; y: number; z: number }
}

class GridStub {
  spacing: { x: number; y: number; z: number }
  origin: { x: number; y: number; z: number }
  private voxelMap: Map<string, SerializedVoxel>
  private voxelList: SerializedVoxel[]

  constructor (grid: CsgJobInput["grid"]) {
    this.spacing = grid.spacing
    this.origin = grid.origin
    this.voxelList = grid.voxels
    this.voxelMap = new Map()
    for (const v of grid.voxels) {
      this.voxelMap.set(GridStub._key(v.x, v.y, v.z), v)
    }
  }

  private static _key (x: number, y: number, z: number): string {
    return `${String(x)}-${String(y)}-${String(z)}`
  }

  forEachVoxel (callback: (voxel: VoxelLike) => void) {
    for (const v of this.voxelList) {
      callback({
        enabled: v.enabled,
        position: { x: v.x, y: v.y, z: v.z },
      })
    }
  }

  hasVoxelAt (x: number, y: number, z: number): boolean {
    return this.voxelMap.has(GridStub._key(x, y, z))
  }

  getVoxel (x: number, y: number, z: number): VoxelLike {
    const v = this.voxelMap.get(GridStub._key(x, y, z))
    if (!v) {
      return { enabled: false, position: { x, y, z } }
    }
    return {
      enabled: v.enabled,
      position: { x: v.x, y: v.y, z: v.z },
    }
  }

  mapVoxelToWorld (point: { x: number; y: number; z: number }) {
    return {
      x: (point.x * this.spacing.x) + this.origin.x,
      y: (point.y * this.spacing.y) + this.origin.y,
      z: (point.z * this.spacing.z) + this.origin.z,
    }
  }
}

let csgExtractor: CsgExtractor | null = null
let cachedModelBspKey: string | null = null
let cachedModelBsp: ThreeBSP | undefined = undefined

function deserializeGeometry (mesh: SerializedFaceVertexMesh): THREE.Geometry {
  const geometry = new THREE.Geometry()
  for (let i = 0; i < mesh.vertexCoordinates.length; i += 3) {
    geometry.vertices.push(new THREE.Vector3(
      mesh.vertexCoordinates[i],
      mesh.vertexCoordinates[i + 1],
      mesh.vertexCoordinates[i + 2],
    ))
  }
  for (let i = 0; i < mesh.faceVertexIndices.length; i += 3) {
    let normal: THREE.Vector3 | undefined
    if (mesh.faceNormalCoordinates) {
      normal = new THREE.Vector3(
        mesh.faceNormalCoordinates[i] ?? 0,
        mesh.faceNormalCoordinates[i + 1] ?? 0,
        mesh.faceNormalCoordinates[i + 2] ?? 0,
      )
    }
    geometry.faces.push(new THREE.Face3(
      mesh.faceVertexIndices[i],
      mesh.faceVertexIndices[i + 1],
      mesh.faceVertexIndices[i + 2],
      normal,
    ))
  }
  return geometry
}

function serializeGeometry (geometry: THREE.Geometry): SerializedFaceVertexMesh {
  const vertexCoordinates: number[] = Array<number>(geometry.vertices.length * 3)
  for (let i = 0; i < geometry.vertices.length; i++) {
    const v = geometry.vertices[i]
    vertexCoordinates[i * 3] = v.x
    vertexCoordinates[(i * 3) + 1] = v.y
    vertexCoordinates[(i * 3) + 2] = v.z
  }
  const faceVertexIndices: number[] = Array<number>(geometry.faces.length * 3)
  const faceNormalCoordinates: number[] = Array<number>(geometry.faces.length * 3)
  for (let i = 0; i < geometry.faces.length; i++) {
    const f = geometry.faces[i]
    faceVertexIndices[i * 3] = f.a
    faceVertexIndices[(i * 3) + 1] = f.b
    faceVertexIndices[(i * 3) + 2] = f.c
    const n = f.normal
    faceNormalCoordinates[i * 3] = n.x
    faceNormalCoordinates[(i * 3) + 1] = n.y
    faceNormalCoordinates[(i * 3) + 2] = n.z
  }
  return { vertexCoordinates, faceVertexIndices, faceNormalCoordinates }
}

export function runCsgJob (input: CsgJobInput): CsgJobResult {
  const transformedModel = deserializeGeometry(input.model)
  const grid = new GridStub(input.grid)

  if (csgExtractor == null) {
    csgExtractor = new CsgExtractor()
  }

  const useCachedBsp = input.cacheKey != null
    && input.cacheKey === cachedModelBspKey
    && cachedModelBsp != null

  const extractorOptions: Parameters<CsgExtractor["extractGeometry"]>[1] = {
    transformedModel,
  }
  if (input.options.addStuds !== undefined) {
    extractorOptions.addStuds = input.options.addStuds
  }
  if (input.options.studSize !== undefined) {
    extractorOptions.studSize = input.options.studSize
  }
  if (input.options.holeSize !== undefined) {
    extractorOptions.holeSize = input.options.holeSize
  }
  if (useCachedBsp && cachedModelBsp) {
    extractorOptions.modelBsp = cachedModelBsp
  }

  const result = csgExtractor.extractGeometry(
    grid as unknown as Parameters<CsgExtractor["extractGeometry"]>[0],
    extractorOptions,
  )

  if (input.cacheKey != null) {
    cachedModelBsp = result.modelBsp
    cachedModelBspKey = input.cacheKey
  }

  if (result.csg == null) {
    return { geometries: [], isOriginalModel: false, everythingBricks: true }
  }

  const cleanOptions: Parameters<typeof clean>[1] = {
    split: true,
    filterSmallGeometries: !result.isOriginalModel,
  }
  if (input.options.minimalPrintVolume !== undefined) {
    cleanOptions.minimalPrintVolume = input.options.minimalPrintVolume
  }

  const cleaned = clean(result.csg, cleanOptions)

  return {
    geometries: cleaned.map(g => serializeGeometry(g)),
    isOriginalModel: result.isOriginalModel,
    everythingBricks: false,
  }
}

export function clearCsgWorkerCache () {
  cachedModelBsp = undefined
  cachedModelBspKey = null
}

export const csgWorkerHelpers = {
  serializeGeometry,
  deserializeGeometry,
}
