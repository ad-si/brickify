import PreviewAssemblyUi from "./PreviewAssemblyUi.js"

export default class PreviewUi {
  constructor (workflowUi) {
    this.setEnabled = this.setEnabled.bind(this)
    this.quit = this.quit.bind(this)
    this._initStabilityView = this._initStabilityView.bind(this)
    this._quitStabilityView = this._quitStabilityView.bind(this)
    this.toggleStabilityView = this.toggleStabilityView.bind(this)
    this._initAssemblyView = this._initAssemblyView.bind(this)
    this._quitAssemblyView = this._quitAssemblyView.bind(this)
    this.toggleAssemblyView = this.toggleAssemblyView.bind(this)
    this.workflowUi = workflowUi
    this.$panel = $("#previewGroup")
    this.sceneManager = this.workflowUi.bundle.sceneManager
    this._initStabilityView()
    this._initAssemblyView()
  }

  // Lazy getters for plugins - these are not available during construction
  // because plugins are loaded asynchronously after the UI is created
  get nodeVisualizer () {
    return this.workflowUi.bundle.getPlugin("nodeVisualizer")
  }

  get editController () {
    return this.workflowUi.bundle.getPlugin("editController")
  }

  get newBrickator () {
    return this.workflowUi.bundle.getPlugin("newBrickator")
  }

  setEnabled (enabled) {
    this.$panel.find(".btn, .panel, h4")
      .toggleClass("disabled", !enabled)
    if (!enabled) {
      return this.quit()
    }
  }

  quit () {
    this._quitStabilityView()
    return this._quitAssemblyView()
  }

  _initStabilityView () {
    this.stabilityViewEnabled = false
    this.$stabilityViewButton = $("#stabilityCheckButton")
    return this.$stabilityViewButton.click(() => {
      this.toggleStabilityView()
      return this.workflowUi.hideMenuIfPossible()
    })
  }

  _quitStabilityView () {
    if (!this.stabilityViewEnabled) {
      return
    }
    this.$stabilityViewButton.removeClass("active disabled")
    this.stabilityViewEnabled = false
    return this.editController.enableInteraction()
  }

  toggleStabilityView () {
    this.stabilityViewEnabled = !this.stabilityViewEnabled
    this._quitAssemblyView()

    if (this.stabilityViewEnabled) {
      this.workflowUi.enableOnly(this)
    }
    else {
      this.workflowUi.enableAll()
    }

    this.$stabilityViewButton.toggleClass("active", this.stabilityViewEnabled)
    this.$assemblyViewButton.toggleClass("disabled", this.stabilityViewEnabled)

    if (this.stabilityViewEnabled) {
      this.editController.disableInteraction()
      return this.nodeVisualizer.setDisplayMode(this.sceneManager.selectedNode, "stability")
    }
    else {
      return this.editController.enableInteraction()
    }
  }

  _initAssemblyView () {
    this.assemblyViewEnabled = false
    this.$assemblyViewButton = $("#buildButton")
    this.$assemblyViewButton.click(this.toggleAssemblyView)
    return this.previewAssemblyUi = new PreviewAssemblyUi(this)
  }

  _quitAssemblyView () {
    if (!this.assemblyViewEnabled) {
      return
    }
    this.$assemblyViewButton.removeClass("active disabled")
    this.assemblyViewEnabled = false
    this.previewAssemblyUi.setEnabled(false)
    return this.editController.enableInteraction()
  }

  toggleAssemblyView () {
    this.assemblyViewEnabled = !this.assemblyViewEnabled
    this._quitStabilityView()

    if (this.assemblyViewEnabled) {
      this.workflowUi.enableOnly(this)
    }
    else {
      this.workflowUi.enableAll()
    }

    this.$assemblyViewButton.toggleClass("active", this.assemblyViewEnabled)
    this.$stabilityViewButton.toggleClass("disabled", this.assemblyViewEnabled)

    this.previewAssemblyUi.setEnabled(this.assemblyViewEnabled)

    if (this.assemblyViewEnabled) {
      return this.editController.disableInteraction()
    }
    else {
      return this.editController.enableInteraction()
    }
  }
}
