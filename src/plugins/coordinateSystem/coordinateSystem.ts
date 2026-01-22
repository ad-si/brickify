/*
  *Coordinate System Plugin#

  Creates a colored coordinate system and a grid base surface for better
  navigation inside brickify.
*/

// Require sub-modules, see [Grid](grid.html) and [Axis](axis.html)
import type { Object3D } from "three"
import type Bundle from "../../client/bundle.js"
import type { GlobalConfig } from "../../types/index.js"
import setupGrid from "./grid.js"
import setupAxis from "./axis.js"

interface FidelityOptions {
  screenshotMode?: boolean;
}

export default class CoordinateSystem {
  globalConfig!: GlobalConfig
  threejsNode!: Object3D
  isVisible: boolean = false

  // Store the global configuration for later use by init3d
  constructor () {
    this.init3d = this.init3d.bind(this)
    this.toggleVisibility = this.toggleVisibility.bind(this)
    this.setFidelity = this.setFidelity.bind(this)
  }

  init (bundle: Bundle) {
    this.globalConfig = bundle.globalConfig
  }

  // Generate the grid and the axis on 3d scene initialization
  init3d (threejsNode: Object3D) {
    this.threejsNode = threejsNode
    setupGrid(this.threejsNode, this.globalConfig)
    setupAxis(this.threejsNode, this.globalConfig)
    this.isVisible = false
    return this.threejsNode.visible = false
  }

  toggleVisibility () {
    this.threejsNode.visible = !this.threejsNode.visible
    return this.isVisible = !this.isVisible
  }

  setFidelity (_fidelityLevel: number, _availableLevels: string[], options: FidelityOptions): void {
    if (options.screenshotMode != null) {
      this.threejsNode.visible = this.isVisible && !options.screenshotMode
    }
  }
}
