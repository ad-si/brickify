import BrushHandler from "./BrushHandler.js"
import PointEventHandler from "./pointEventHandler.js"
import pointerEnums from "../../client/ui/pointerEnums.js"

export default class EditController {
  constructor () {
    this.disableInteraction = this.disableInteraction.bind(this)
    this.enableInteraction = this.enableInteraction.bind(this)
    this.onPointerEvent = this.onPointerEvent.bind(this)
    this.relayoutModifiedParts = this.relayoutModifiedParts.bind(this)
    this.rerunLegoPipeline = this.rerunLegoPipeline.bind(this)
    this.interactionDisabled = false
  }

  init (bundle) {
    this.bundle = bundle
    this.nodeVisualizer = this.bundle.getPlugin("nodeVisualizer")
    this.newBrickator = this.bundle.getPlugin("newBrickator")

    this.brushHandler = new BrushHandler(this.bundle, this.nodeVisualizer, this)

    const {
      brushUi,
    } = this.bundle.ui.workflowUi.workflow.edit
    brushUi.setBrushes(this.brushHandler.getBrushes())

    return this.pointEventHandler = new PointEventHandler(
      this.bundle.sceneManager,
      brushUi,
    )
  }

  // Disables any brush interaction for the user
  disableInteraction () {
    return this.interactionDisabled = true
  }

  // Enables brush interaction for the user and sets correct display
  // mode for the currently selected brush
  enableInteraction () {
    this.interactionDisabled = false

    if (this.brushHandler.legoBrushSelected) {
      return this.nodeVisualizer.setDisplayMode(
        this.bundle.sceneManager.selectedNode, "legoBrush",
      )
    }
    else {
      return this.nodeVisualizer.setDisplayMode(
        this.bundle.sceneManager.selectedNode, "printBrush",
      )
    }
  }

  onPointerEvent (event, eventType) {
    if (this.interactionDisabled) {
      return false
    }
    if ((this.nodeVisualizer == null) || (this.pointEventHandler == null)) {
      return false
    }

    const ignoreInvisible = event.buttons !== pointerEnums.buttonStates.right
    if (!this.nodeVisualizer.pointerOverModel(event, ignoreInvisible)) {
      // when we are not above model, call only move and up events
      switch (eventType) {
        case pointerEnums.events.PointerMove:
          return this.pointEventHandler.pointerMove(event)
          break
        case pointerEnums.events.PointerUp:
          return this.pointEventHandler.pointerUp(event)
          break
      }
      return false
    }

    switch (eventType) {
      case pointerEnums.events.PointerDown:
        return this.pointEventHandler.pointerDown(event)
        break
      case pointerEnums.events.PointerMove:
        return this.pointEventHandler.pointerMove(event)
        break
      case pointerEnums.events.PointerUp:
        return this.pointEventHandler.pointerUp(event)
        break
      case pointerEnums.events.PointerCancel:
        return this.pointEventHandler.PointerCancel(event)
        break
    }
    return false
  }

  // Methods called by brush handler
  relayoutModifiedParts (
    selectedNode, cachedData, touchedVoxels, createBricks) {
    return this.newBrickator.relayoutModifiedParts(selectedNode, touchedVoxels, createBricks)
  }

  rerunLegoPipeline (selectedNode) {
    return this.newBrickator.runLegoPipeline(selectedNode)
  }
}
