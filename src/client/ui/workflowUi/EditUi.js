import EditBrushUi from "./EditBrushUi.js"

export default class EditUi {
  constructor (workflowUi) {
    this.setEnabled = this.setEnabled.bind(this)
    this._initBrushes = this._initBrushes.bind(this)
    this._initPartList = this._initPartList.bind(this)
    this.onNodeSelect = this.onNodeSelect.bind(this)
    this.onNodeDeselect = this.onNodeDeselect.bind(this)
    this.workflowUi = workflowUi
    this.$panel = $("#editGroup")
    this.bundle = this.workflowUi.bundle

    this._initPartList()
    this._initBrushes()
  }

  setEnabled (enabled) {
    return this.$panel.find(".btn, .panel, h4, .estimate, #editControls")
      .toggleClass("disabled", !enabled)
  }

  _initBrushes () {
    this.brushUi = new EditBrushUi(this.workflowUi)
    return this.brushUi.init("#brushContainer", "#bigBrushContainer")
  }

  _initPartList () {
    this.legoInstructions = this.bundle.getPlugin("lego-instructions")
    if (this.legoInstructions == null) {
      return
    }

    return $("#brickCountContainer")
      .click(() => {
        if (this.bundle.sceneManager.selectedNode == null) {
          return
        }
        return this.legoInstructions.showPartListPopup(this.bundle.sceneManager.selectedNode)
      })
  }

  onNodeSelect (node) {
    return this.brushUi.onNodeSelect(node)
  }

  onNodeDeselect (node) {
    return this.brushUi.onNodeDeselect(node)
  }
}
