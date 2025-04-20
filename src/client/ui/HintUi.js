export default class HintUi {
  constructor () {
    this.pointerDown = this.pointerDown.bind(this)
    this.pointerMove = this.pointerMove.bind(this)
    this.mouseWheel = this.mouseWheel.bind(this)
    this._anyHintVisible = this._anyHintVisible.bind(this)
    this.$hintContainer = $("#usageHintContainer")
    this.$moveHint = this.$hintContainer.find("#moveHint")
    this.$brushHint = this.$hintContainer.find("#brushHint")
    this.$rotateHint = this.$hintContainer.find("#rotateHint")
    this.$zoomHint = this.$hintContainer.find("#zoomHint")

    if (this._userNeedsHint()) {
      this.$hintContainer.show()
      this.moveHintVisible = true
      this.brushHintVisible = true
      this.rotateHintVisible = true
      this.zoomHintVisible = true
    }
  }

  pointerDown (event, handled) {
    if (event.buttons === 0) {
      return
    }

    switch (event.buttons) {
      case 1: case 2:
        // Left or right mouse button
        if (handled) {
          this.$brushHint.fadeOut()
          this.brushHintVisible = false
        }
        break
    }

    if (!this._anyHintVisible()) {
      this.$hintContainer.hide()
      return this._disableHintsOnReload()
    }
  }

  pointerMove (event, handled) {
    // Ignore plain mouse movement
    if (event.buttons === 0) {
      return
    }

    switch (event.buttons) {
      case 1:
        // Left mouse button
        if (!handled) {
          this.$rotateHint.fadeOut()
          this.rotateHintVisible = false
        }
        else {
          this.$brushHint.fadeOut()
          this.brushHintVisible = false
        }
        break
      case 4:
        // Middle mouse button
        this.$zoomHint.fadeOut()
        this.zoomHintVisible = false
        break
      case 2:
        // Right mouse button
        if (!handled) {
          this.$moveHint.fadeOut()
          this.moveHintVisible = false
        }
        else {
          this.$brushHint.fadeOut()
          this.brushHintVisible = false
        }
        break
    }

    if (!this._anyHintVisible()) {
      this.$hintContainer.hide()
      return this._disableHintsOnReload()
    }
  }

  mouseWheel () {
    this.$zoomHint.fadeOut()
    return this.zoomHintVisible = false
  }

  // Checks whether a cookie for hints exists,
  // sets one if it does not exist
  _userNeedsHint () {
    return document.cookie.indexOf("usageHintsShown=yes") < 0
  }

  // Disables the hints for the next 5 days
  _disableHintsOnReload () {
    const d = new Date()
    d.setDate(d.getDate() + 5)

    let cookieString = "usageHintsShown=yes; expires="
    cookieString += d.toUTCString()

    return document.cookie = cookieString
  }

  _anyHintVisible () {
    return this.moveHintVisible || this.brushHintVisible ||
    this.zoomHintVisible || this.rotateHintVisible
  }
}
