import Hotkeys from "../hotkeys.js"
import PointerDispatcher from "./pointerDispatcher.js"
import WorkflowUi from "./workflowUi/workflowUi.js"
import HintUi from "./HintUi.js"

/*
 * @module ui
 */
export default class Ui {
  constructor (bundle) {
    this.windowResizeHandler = this.windowResizeHandler.bind(this)
    this.init = this.init.bind(this)
    this._initListeners = this._initListeners.bind(this)
    this._initHotkeys = this._initHotkeys.bind(this)
    this._toggleGridVisibility = this._toggleGridVisibility.bind(this)
    this._toggleStabilityView = this._toggleStabilityView.bind(this)
    this._toggleAssemblyView = this._toggleAssemblyView.bind(this)
    this._toggleRendering = this._toggleRendering.bind(this)
    this.bundle = bundle
    this.renderer = this.bundle.renderer
    this.pluginHooks = this.bundle.pluginHooks
    this.workflowUi = new WorkflowUi(this.bundle)
    this.workflowUi.init()
    this.hintUi = new HintUi()
    this.pointerDispatcher = new PointerDispatcher(this.bundle, this.hintUi)
  }

  // Bound to updates to the window size:
  // Called whenever the window is resized.
  windowResizeHandler (event) {
    return this.renderer.windowResizeHandler()
  }

  init () {
    this._initListeners()
    return this._initHotkeys()
  }

  _initListeners () {
    this.pointerDispatcher.init()

    return window.addEventListener(
      "resize",
      this.windowResizeHandler,
    )
  }

  _initHotkeys () {
    this.hotkeys = new Hotkeys(this.pluginHooks, this.bundle.sceneManager)
    this.hotkeys.addEvents(this.bundle.sceneManager.getHotkeys())

    const gridHotkeys = {
      title: "UI",
      events: [
        {
          description: "Toggle coordinate system / lego plate",
          hotkey: "g",
          callback: this._toggleGridVisibility,
        },
        {
          description: "Toggle stability view",
          hotkey: "s",
          callback: this._toggleStabilityView,
        },
        {
          description: "Toggle LEGO assembly view",
          hotkey: "l",
          callback: this._toggleAssemblyView,
        },
      ],
    }
    if (process.env.NODE_ENV === "development") {
      gridHotkeys.events.push({
        description: "Toggle rendering",
        hotkey: "p",
        callback: this._toggleRendering,
      })
    }
    return this.hotkeys.addEvents(gridHotkeys)
  }

  _toggleGridVisibility () {
    this.bundle.getPlugin("lego-board")
      .toggleVisibility()
    return this.bundle.getPlugin("coordinate-system")
      .toggleVisibility()
  }

  _toggleStabilityView () {
    return this.workflowUi.toggleStabilityView()
  }

  _toggleAssemblyView () {
    return this.workflowUi.toggleAssemblyView()
  }

  _toggleRendering () {
    const fidelityControl = this.bundle.getPlugin("FidelityControl")
    if (fidelityControl != null) {
      fidelityControl.reset()
    }
    return this.renderer.toggleRendering()
  }
}
