/*
  *Coordinate System Plugin#

  Creates a colored coordinate system and a grid base surface for better
  navigation inside brickify.
*/

// Require sub-modules, see [Grid](grid.html) and [Axis](axis.html)
import setupGrid from "./grid.js"
import setupAxis from "./axis.js"

export default class CoordinateSystem {
  // Store the global configuration for later use by init3d
  constructor () {
    this.init3d = this.init3d.bind(this)
    this.toggleVisibility = this.toggleVisibility.bind(this)
    this.setFidelity = this.setFidelity.bind(this)
  }

  init (bundle) {
    this.globalConfig = bundle.globalConfig
  }

  // Generate the grid and the axis on 3d scene initialization
  init3d (threejsNode) {
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

  setFidelity (fidelityLevel, availableLevels, options) {
    if (options.screenshotMode != null) {
      return this.threejsNode.visible = this.isVisible && !options.screenshotMode
    }
  }
}
