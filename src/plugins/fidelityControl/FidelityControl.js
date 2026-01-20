/**
 * Fidelity Control Plugin
 *
 * Measures the current FPS and instigates rendering fidelity changes
 * accordingly via the `uglify()` and `beautify()` plugin hooks
 */

import $ from "jquery"


const minimalAcceptableFps = 20
const upgradeThresholdFps = 40
const accumulationTime = 200
const timesBelowThreshold = 10
const fpsDisplayUpdateTime = 1000
const maxNoPipelineDecisions = 3

/*
 * @class FidelityControl
 */
export default class FidelityControl {
  constructor () {
    this.init = this.init.bind(this)
    this.on3dUpdate = this.on3dUpdate.bind(this)
    this._adjustFidelity = this._adjustFidelity.bind(this)
    this._increaseFidelity = this._increaseFidelity.bind(this)
    this._decreaseFidelity = this._decreaseFidelity.bind(this)
    this._setFidelity = this._setFidelity.bind(this)
    this.getHotkeys = this.getHotkeys.bind(this)
    this._manualIncrease = this._manualIncrease.bind(this)
    this._manualDecrease = this._manualDecrease.bind(this)
    this._setupFpsDisplay = this._setupFpsDisplay.bind(this)
    this._showFps = this._showFps.bind(this)
    this.enableScreenshotMode = this.enableScreenshotMode.bind(this)
    this.disableScreenshotMode = this.disableScreenshotMode.bind(this)
    this.reset = this.reset.bind(this)
  }

  static initClass () {
    this.fidelityLevels = [
      "DefaultLow",
      "DefaultMedium",
      "DefaultHigh",
      "PipelineLow",
      "PipelineMedium",
      "PipelineHigh",
      "PipelineUltra",
    ]
    this.minimalPipelineLevel = this.fidelityLevels.indexOf("PipelineLow")
  }

  init (bundle) {
    this.bundle = bundle
    this.pluginHooks = this.bundle.pluginHooks

    this.currentFidelityLevel = 0

    this.autoAdjust = true
    this.screenShotMode = false

    this.accumulatedFrames = 0
    this.accumulatedTime = 0

    this.timesBelowMinimumFps = 0

    this.showFps = process.env.NODE_ENV === "development"
    this._setupFpsDisplay()

    // allow pipeline only if we have the needed extension and a stencil buffer
    // and if the pipeline is enabled in the global config
    const {
      usePipeline,
    } = this.bundle.globalConfig.rendering
    const depth = this.bundle.renderer.threeRenderer.supportsDepthTextures()
    const fragDepth = this.bundle.renderer.threeRenderer.extensions.get("EXT_frag_depth")
    const stencilBuffer = this.bundle.renderer.threeRenderer.hasStencilBuffer

    let capabilites = ""
    if (depth != null) {
      capabilites += "DepthTextures "
    }
    if (fragDepth != null) {
      capabilites += "ExtFragDepth "
    }
    if (stencilBuffer) {
      capabilites += "stencilBuffer "
    }

    this.pipelineAvailable = usePipeline && (depth != null) && (fragDepth != null) && stencilBuffer
    return this.noPipelineDecisions = 0
  }

  on3dUpdate (timestamp) {
    if (this._lastTimestamp == null) {
      this._lastTimestamp = timestamp
      return
    }

    const delta = timestamp - this._lastTimestamp

    this._lastTimestamp = timestamp
    this.accumulatedTime += delta
    this.accumulatedFrames++

    if (this.accumulatedTime > accumulationTime) {
      const fps = (this.accumulatedFrames / this.accumulatedTime) * 1000
      this.accumulatedFrames = 0
      this.accumulatedTime %= accumulationTime
      this._adjustFidelity(fps)
      this._showFps(timestamp, fps)
    }
  }

  _adjustFidelity (fps) {
    if (this.screenShotMode || !this.autoAdjust) {
      return
    }

    if ((fps < minimalAcceptableFps) && (this.currentFidelityLevel > 0)) {
      // count how often we dropped below the desired fps
      // it has to occur at least @timesBelowThreshold times to cause a change
      this.timesBelowMinimumFps++
      if (this.timesBelowMinimumFps < timesBelowThreshold) {
        return
      }

      this.timesBelowMinimumFps = 0
      if (this.currentFidelityLevel === FidelityControl.minimalPipelineLevel) {
        this.noPipelineDecisions++
      }
      return this._decreaseFidelity()

    }
    else if ((fps > upgradeThresholdFps) &&
    (this.currentFidelityLevel < (FidelityControl.fidelityLevels.length - 1))) {
      // upgrade instantly, but reset downgrade counter
      this.timesBelowMinimumFps = 0
      if (this.currentFidelityLevel === (FidelityControl.minimalPipelineLevel - 1)) {
        if (this.noPipelineDecisions > maxNoPipelineDecisions) {
          return
        }
      }
      return this._increaseFidelity()
    }
  }

  _increaseFidelity () {
    // only allow pipeline when we have the extensions needed for it
    if ((this.currentFidelityLevel === 2) && !this.pipelineAvailable) {
      return
    }

    // Increase fidelity
    this.currentFidelityLevel++
    return this._setFidelity()
  }

  _decreaseFidelity () {
    // Decrease fidelity
    this.currentFidelityLevel--
    return this._setFidelity()
  }

  _setFidelity () {
    this.pluginHooks.setFidelity(
      this.currentFidelityLevel, FidelityControl.fidelityLevels, {},
    )

    return this.bundle.renderer.setFidelity(
      this.currentFidelityLevel, FidelityControl.fidelityLevels, {},
    )
  }

  getHotkeys () {
    return {
      title: "Visual Complexity",
      events: [
        {
          description: "Increase visual complexity (turns off automatic adjustment)",
          hotkey: "i",
          callback: this._manualIncrease,
        },
        {
          description: "Decrease visual complexity (turns off automatic adjustment)",
          hotkey: "d",
          callback: this._manualDecrease,
        },
      ],
    }
  }

  _manualIncrease () {
    this.autoAdjust = false
    if (this.currentFidelityLevel < (FidelityControl.fidelityLevels.length - 1)) {
      return this._increaseFidelity()
    }
  }

  _manualDecrease () {
    this.autoAdjust = false
    if (this.currentFidelityLevel > 0) {
      return this._decreaseFidelity()
    }
  }

  _setupFpsDisplay () {
    if (!this.showFps) {
      return
    }
    this.lastDisplayUpdate = 0
    this.$fpsDisplay = $('<div class="fps-display"></div>')
    return $("body")
      .append(this.$fpsDisplay)
  }

  _showFps (timestamp, fps) {
    if (!this.showFps) {
      return
    }
    if ((timestamp - this.lastDisplayUpdate) > fpsDisplayUpdateTime) {
      this.lastDisplayUpdate = timestamp
      const levelAbbreviation = FidelityControl.fidelityLevels[this.currentFidelityLevel]
        .match(/[A-Z]/g)
        .join("")
      const fpsText = Math.round(fps) + "/" + levelAbbreviation
      return this.$fpsDisplay.text(fpsText)
    }
  }

  // disables pipeline for screenshots
  enableScreenshotMode () {
    this.screenShotMode = true

    const level = FidelityControl.fidelityLevels.indexOf("DefaultHigh")
    this._levelBeforeScreenshot = this.currentFidelityLevel
    this.currentFidelityLevel = level

    this.pluginHooks.setFidelity(
      level, FidelityControl.fidelityLevels,
      {screenshotMode: true},
    )
    return this.bundle.renderer.setFidelity(
      level, FidelityControl.fidelityLevels,
      {screenshotMode: true},
    )
  }

  // resets screenshot mode, restores old fidelity level
  disableScreenshotMode () {
    this.screenShotMode = false

    this.currentFidelityLevel = this._levelBeforeScreenshot

    this.pluginHooks.setFidelity(
      this.currentFidelityLevel, FidelityControl.fidelityLevels,
      {screenshotMode: false},
    )
    return this.bundle.renderer.setFidelity(
      this.currentFidelityLevel, FidelityControl.fidelityLevels,
      {screenshotMode: false},
    )
  }

  reset () {
    this.accumulatedFrames = 0
    this.accumulatedTime = 0
    this.timesBelowMinimumFps = 0
    return this._lastTimestamp = null
  }
}
FidelityControl.initClass()
