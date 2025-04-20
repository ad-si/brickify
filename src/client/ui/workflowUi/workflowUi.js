import perfectScrollbar from "perfect-scrollbar"

import LoadUi from "./LoadUi.js"
import EditUi from "./EditUi.js"
import PreviewUi from "./PreviewUi.js"
import ExportUi from "./ExportUi.js"

export default class WorkflowUi {
  constructor (bundle) {
    this.onNodeAdd = this.onNodeAdd.bind(this);   this.onNodeRemove = this.onNodeRemove.bind(this);   this.onNodeSelect = this.onNodeSelect.bind(this);   this.onNodeDeselect = this.onNodeDeselect.bind(this);   this.enableOnly = this.enableOnly.bind(this);   this.enableAll = this.enableAll.bind(this);   this._enable = this._enable.bind(this);   this.init = this.init.bind(this);   this.toggleStabilityView = this.toggleStabilityView.bind(this);   this.toggleAssemblyView = this.toggleAssemblyView.bind(this);   this.bundle = bundle
  }

  // Called by sceneManager when a node is added
  onNodeAdd (node) {
    return this._enable(["load", "edit", "preview", "export"])
  }

  // Called by sceneManager when a node is removed
  onNodeRemove (node) {
    this.workflow.preview.quit()
    return this.bundle.sceneManager.scene.then(scene => {
      if (scene.nodes.length === 0) {
        return this.enableOnly(this.workflow.load)
      }
    })
  }

  onNodeSelect (node) {
    return this.workflow.edit.onNodeSelect(node)
  }

  onNodeDeselect (node) {
    return this.workflow.edit.onNodeDeselect(node)
  }

  enableOnly (groupUi) {
    return (() => {
      const result = []
      for (const step in this.workflow) {
        const ui = this.workflow[step]
        result.push(ui.setEnabled(ui === groupUi))
      }
      return result
    })()
  }

  enableAll () {
    return this._enable(Object.keys(this.workflow))
  }

  _enable (groupsList) {
    return (() => {
      const result = []
      for (const step in this.workflow) {
        const ui = this.workflow[step]
        result.push(ui.setEnabled(Array.from(groupsList)
          .includes(step)))
      }
      return result
    })()
  }

  init () {
    this.workflow = {
      load: new LoadUi(this),
      edit: new EditUi(this),
      preview: new PreviewUi(this),
      export: new ExportUi(this),
    }

    this.enableOnly(this.workflow.load)

    this._initScrollbar()
    return this._initToggleButton()
  }

  _initScrollbar () {
    const sidebar = document.getElementById("leftSidebar")
    perfectScrollbar.initialize(sidebar)
    return window.addEventListener("resize", () => perfectScrollbar.update(sidebar))
  }

  _initToggleButton () {
    return $("#toggleMenu")
      .click(() => this.toggleMenu())
  }

  toggleMenu () {
    $("#leftSidebar")
      .css({height: "auto"})
    return $("#sidebar-content")
      .slideToggle(null, () => {
        $("#leftSidebar")
          .toggleClass("collapsed-sidebar")
        return $("#leftSidebar")
          .css({height: ""})
      })
  }

  hideMenuIfPossible () {
    if (!($("#toggleMenu:visible").length > 0)) {
      return
    }
    $("#leftSidebar")
      .css({height: "auto"})
    return $("#sidebar-content")
      .slideUp(null, () => {
        $("#leftSidebar")
          .addClass("collapsed-sidebar")
        return $("#leftSidebar")
          .css({height: ""})
      })
  }

  toggleStabilityView () {
    return this.workflow.preview.toggleStabilityView()
  }

  toggleAssemblyView () {
    return this.workflow.preview.toggleAssemblyView()
  }
}
