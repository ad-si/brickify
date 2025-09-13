import * as pointerEnums from "../../client/ui/pointerEnums.js"

export default class PointEventHandler {
  constructor (sceneManager, brushUi) {
    this.pointerDown = this.pointerDown.bind(this)
    this.pointerMove = this.pointerMove.bind(this)
    this.pointerUp = this.pointerUp.bind(this)
    this.pointerCancel = this.pointerCancel.bind(this)
    this._untoggleBrush = this._untoggleBrush.bind(this)
    this.sceneManager = sceneManager
    this.brushUi = brushUi
    this.isBrushing = false
    this.brushToggled = false
  }

  pointerDown (event) {
    if (!this._validBrushButton(event)) {
      return false
    }

    // toggle brush if it is the right mouse button
    if (event.buttons & pointerEnums.buttonStates.right) {
      this.brushToggled = this.brushUi.toggleBrush()
    }

    // perform brush action
    this.isBrushing = true
    __guardMethod__(this.brushUi.getSelectedBrush(), "onBrushDown", o => o.onBrushDown(event, this.sceneManager.selectedNode))
    return true
  }

  pointerMove (event) {
    if (!this._validBrushButton(event)) {
      this.pointerCancel(event)
      return false
    }

    // perform brush action
    const brush = this.brushUi.getSelectedBrush()
    if (brush == null) {
      return false
    }

    if (this.isBrushing) {
      if (typeof brush.onBrushMove === "function") {
        brush.onBrushMove(event, this.sceneManager.selectedNode)
      }
      return true
    }
    else if (event.buttons === pointerEnums.buttonStates.none) {
      if (typeof brush.onBrushOver === "function") {
        brush.onBrushOver(event, this.sceneManager.selectedNode)
      }
      return true
    }
  }

  pointerUp (event) {
    if (!this.isBrushing) {
      return false
    }

    // end brush action
    this.isBrushing = false
    __guardMethod__(this.brushUi.getSelectedBrush(), "onBrushUp", o => o.onBrushUp(event, this.sceneManager.selectedNode))

    this._untoggleBrush()
    return true
  }

  pointerCancel (event) {
    if (!this.isBrushing) {
      return false
    }

    this.isBrushing = false
    __guardMethod__(this.brushUi.getSelectedBrush(), "onBrushCancel", o => o.onBrushCancel(
      event, this.sceneManager.selectedNode,
    ))

    this._untoggleBrush()
    return true
  }

  _untoggleBrush () {
    if (this.brushToggled) {
      this.brushUi.toggleBrush()
      return this.brushToggled = false
    }
  }

  _validBrushButton (event) {
    if ([
      pointerEnums.buttonStates.none,
      pointerEnums.buttonStates.left,
      pointerEnums.buttonStates.right,
    ].includes(event.buttons)) {
      return true
    }
    return false
  }
}

function __guardMethod__ (obj, methodName, transform) {
  if (typeof obj !== "undefined" && obj !== null && typeof obj[methodName] === "function") {
    return transform(obj, methodName)
  }
  else {
    return undefined
  }
}
