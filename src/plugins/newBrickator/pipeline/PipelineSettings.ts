import type { Matrix4 } from "three"

interface GridSpacing {
  x: number
  y: number
  z: number
}

interface GlobalConfig {
  gridSpacing: GridSpacing
}

export default class PipelineSettings {
  gridSpacing: GridSpacing
  modelTransform: Matrix4 | null
  voxelizing: boolean
  initLayout: boolean
  layouting: boolean
  reLayout: boolean

  constructor (globalConfig: GlobalConfig) {
    this.deactivateLayouting = this.deactivateLayouting.bind(this)
    this.deactivateVoxelizing = this.deactivateVoxelizing.bind(this)
    this.onlyInitLayout = this.onlyInitLayout.bind(this)
    this.onlyRelayout = this.onlyRelayout.bind(this)
    this.setGridSpacing = this.setGridSpacing.bind(this)
    this.setModelTransform = this.setModelTransform.bind(this)
    this.gridSpacing = globalConfig.gridSpacing
    this.modelTransform = null
    this.voxelizing = true
    this.initLayout = true
    this.layouting = true
    this.reLayout = false
  }

  deactivateLayouting () {
    this.initLayout = false
    return this.layouting = false
  }

  deactivateVoxelizing () {
    return this.voxelizing = false
  }

  onlyInitLayout () {
    this.deactivateVoxelizing()
    this.deactivateLayouting()
    this.reLayout = false
    return this.initLayout = true
  }

  onlyRelayout () {
    this.deactivateVoxelizing()
    this.deactivateLayouting()
    return this.reLayout = true
  }

  setGridSpacing (x: number, y: number, z: number) {
    this.gridSpacing.x = x
    this.gridSpacing.y = y
    return this.gridSpacing.z = z
  }

  setModelTransform (transformMatrix: Matrix4 | null) {
    return this.modelTransform = transformMatrix
  }
}
