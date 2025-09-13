import * as pointerEnums from "./pointerEnums.js"

export default class PointerDispatcher {
  constructor (bundle, hintUi) {
    this.init = this.init.bind(this)
    this.initListeners = this.initListeners.bind(this)
    this.onPointerDown = this.onPointerDown.bind(this)
    this.onPointerMove = this.onPointerMove.bind(this)
    this.onPointerUp = this.onPointerUp.bind(this)
    this.onPointerCancel = this.onPointerCancel.bind(this)
    this.onMouseWheel = this.onMouseWheel.bind(this)
    this._capturePointerFor = this._capturePointerFor.bind(this)
    this._releasePointerFor = this._releasePointerFor.bind(this)
    this.onContextMenu = this.onContextMenu.bind(this)
    this.bundle = bundle
    this.hintUi = hintUi
  }

  init () {
    this.sceneManager = this.bundle.sceneManager
    this.brushUi = this.bundle.ui.workflowUi.workflow.edit.brushUi
    return this.initListeners()
  }

  initListeners () {
    const _registerEvent = (element, event) => {
      return element.addEventListener(event.toLowerCase(), this["on" + event])
    }

    const element = this.bundle.ui.renderer.getDomElement()
    element.addEventListener("wheel", this.onMouseWheel)

    return (() => {
      const result = []
      for (const event in pointerEnums.events) {
        result.push(_registerEvent(element, event))
      }
      return result
    })()
  }

  onPointerOver (_event) {
  }

  onPointerEnter (_event) {
  }

  onPointerDown (event) {
    // don't call mouse events if there is no selected node
    if (this.sceneManager.selectedNode == null) {
      return
    }

    // capture event in all cases
    this._capturePointerFor(event)

    // dispatch event
    const handled = this._dispatchEvent(event, pointerEnums.events.PointerDown)

    // notify hint ui
    this.hintUi.pointerDown(event, handled)

    // Stop event if a plugin handled it (else let pointer controls work)
    if (handled) {
      this._stop(event)
    }

  }

  onPointerMove (event) {
    // don't call mouse events if there is no selected node
    if (this.sceneManager.selectedNode == null) {
      // notify hint Ui of unhandled event
      this.hintUi.pointerMove(event, false)
      return
    }

    // dispatch event
    const handled = this._dispatchEvent(event, pointerEnums.events.PointerMove)

    // notify hint ui
    this.hintUi.pointerMove(event, handled)

    // Stop event if a plugin handled it (else let pointer controls work)
    if (handled) {
      this._stop(event)
    }
  }

  onPointerUp (event) {
    // Pointer capture will be implicitly released

    // don't call mouse events if there is no selected node
    if (this.sceneManager.selectedNode == null) {
      return
    }

    // dispatch event
    this._dispatchEvent(event, pointerEnums.events.PointerUp)
  }

  onPointerCancel (event) {
    // Pointer capture will be implicitly released
    this._dispatchEvent(event, pointerEnums.events.PointerCancel)
  }

  onPointerOut (_event) {
  }

  onPointerLeave (_event) {
  }

  onGotPointerCapture (_event) {
  }

  onLostPointerCapture (_event) {
  }

  onMouseWheel (event) {
    this.hintUi.mouseWheel()

    // this is needed because chrome (not firefox/IE) does not
    // handle multiple listeners correctly
    event.target.removeEventListener("wheel", this.onMouseWheel)

    return false
  }

  _capturePointerFor (event) {
    const element = this.bundle.ui.renderer.getDomElement()
    return element.setPointerCapture(event.pointerId)
  }

  _releasePointerFor (event) {
    const element = this.bundle.ui.renderer.getDomElement()
    return element.releasePointerCapture(event.pointerId)
  }

  onContextMenu (event) {
    // this event sometimes interferes with right clicks
    return this._stop(event)
  }

  _stop (event) {
    event.stopPropagation()
    event.stopImmediatePropagation()
    return event.preventDefault()
  }

  // call plugin after plugin until a plugin reacts to this pointer event
  // returns false if no plugin handled this event
  _dispatchEvent (event, type) {
    for (
      const hook of Array.from(
        this.bundle.pluginHooks.get("onPointerEvent"),
      )
    ) {
      if (hook(event, type)) {
        return true
      }
    }
    return false
  }
}
