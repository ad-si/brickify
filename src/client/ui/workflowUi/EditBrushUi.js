/*
 * @class EditBrushUi
 */
export default class EditBrushUi {
  constructor (workflowUi) {
    this.setBrushes = this.setBrushes.bind(this)
    this.init = this.init.bind(this)
    this.onNodeSelect = this.onNodeSelect.bind(this)
    this.onNodeDeselect = this.onNodeDeselect.bind(this)
    this._brushSelect = this._brushSelect.bind(this)
    this._deselectBrush = this._deselectBrush.bind(this)
    this.getSelectedBrush = this.getSelectedBrush.bind(this)
    this.toggleBrush = this.toggleBrush.bind(this)
    this.workflowUi = workflowUi
    this.selectedNode = null

    this._brushList = []
  }

  setBrushes (_brushList) {
    this._brushList = _brushList
    return (() => {
      const result = []
      for (const brush of Array.from(this._brushList)) {
        brush.brushButton = this.brushContainer.find(brush.containerId)
        brush.bigBrushButton = this.bigBrushContainer.find(brush.containerId)
        result.push(this._bindBrushEvent(brush))
      }
      return result
    })()
  }

  init (jQueryBrushContainerSelector, jQueryBigBrushContainerSelector) {
    this._selectedBrush = null
    this._bigBrushSelected = false

    this.brushContainer = $(jQueryBrushContainerSelector)
    this.bigBrushContainer = $(jQueryBigBrushContainerSelector)

    // because firefox ignores the draggable="false" attribute
    // attached to the brush images
    $("#brushContainer img")
      .on("dragstart", () => false)
    return $("#bigBrushContainer img")
      .on("dragstart", () => false)
  }

  onNodeSelect (node) {
    this.selectedNode = node

    if (!this._selectedBrush && (this._brushList.length > 0)) {
      this._bigBrushSelected = false
      return this._brushSelect(this._brushList[this._brushList.length - 1])
    }
  }

  onNodeDeselect (node) {
    this._deselectBrush(node)
    return this.selectedNode = null
  }

  _bindBrushEvent (brush) {
    brush.brushButton.on("click", event => {
      this._bigBrushSelected = false
      this._brushSelect(brush)
      return this.workflowUi.hideMenuIfPossible()
    })
    return brush.bigBrushButton.on("click", event => {
      this._bigBrushSelected = true
      this._brushSelect(brush)
      return this.workflowUi.hideMenuIfPossible()
    })
  }

  _brushSelect (brush) {
    // deselect currently selected brush
    this._deselectBrush(this.selectedNode)

    // select new brush
    this._selectedBrush = brush
    if (!this._bigBrushSelected) {
      brush.brushButton.addClass("active")
    }
    if (this._bigBrushSelected) {
      brush.bigBrushButton.addClass("active")
    }
    return typeof brush.onBrushSelect === "function" ? brush.onBrushSelect(this.selectedNode, this._bigBrushSelected) : undefined
  }

  _deselectBrush (node) {
    if (this._selectedBrush != null) {
      if (typeof this._selectedBrush.onBrushDeselect === "function") {
        this._selectedBrush.onBrushDeselect(node)
      }
      this._selectedBrush.brushButton.removeClass("active")
      this._selectedBrush.bigBrushButton.removeClass("active")
      return this._selectedBrush = null
    }
  }

  getSelectedBrush () {
    return this._selectedBrush
  }

  toggleBrush () {
    for (const brush of Array.from(this._brushList)) {
      if (brush !== this._selectedBrush) {
        this._brushSelect(brush)
        return true
      }
    }
    return false
  }
}
