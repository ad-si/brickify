export default class PipelineSettings {
  constructor (globalConfig) {
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

  setGridSpacing (x, y, z) {
    this.gridSpacing.x = x
    this.gridSpacing.y = y
    return this.gridSpacing.z = z
  }

  setModelTransform (transformMatrix) {
    return this.modelTransform = transformMatrix
  }
}
