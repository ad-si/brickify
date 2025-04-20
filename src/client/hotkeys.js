/*
 *  @class Hotkeys
 */
export default class Hotkeys {
  constructor (pluginHooks, sceneManager) {
    this.showHelp = this.showHelp.bind(this)
    this.sceneManager = sceneManager
    this.bootboxOpen = false
    this.events = []
    this.bind("?", "General", "Show this help", () => {
      return this.showHelp()
    })
    this.bind("esc", "General", "Close modal window", () => bootbox.hideAll())

    for (const events of Array.from(pluginHooks.getHotkeys())) {
      this.addEvents(events)
    }
  }

  showHelp () {
    if (this.bootboxOpen) {
      return
    }
    let message = ""
    for (const group of Object.keys(this.events || {})) {
      const events = this.events[group]
      message += "<section><h4>" + group + "</h4>"
      for (const event of Array.from(events)) {
        message += '<p><span class="keys">'
        const keys = event.hotkey.split("+")
          .map(key => "<kbd>" + key + "</kbd>")
        message += keys.join("+")
        message += "</span> <span>" + event.description + "</span></p>"
      }
      message += "</section>"
    }
    const callback = () => {
      this.bootboxOpen = false
      return true
    }
    this.bootboxOpen = true
    return bootbox.dialog({
      title: "Keyboard shortcuts",
      message,
      buttons: {
        success: {
          label: "Got it!",
          className: "btn-primary",
          callback,
        },
      },
      onEscape: callback,
    })
  }

  /*
   * @param {String} hotkey Event description of Mousescript
   * @param {String} group Title of section to show in help
   * @param {String} description Description to show in help
   * @param {Function} callback Callback to be called when event is triggered
   */
  bind (hotkey, titlegroup, description, callback) {
    Mousetrap.bind(hotkey.toLowerCase(), () => callback(this.sceneManager.selectedNode))
    Mousetrap.bind(hotkey.toUpperCase(), () => callback(this.sceneManager.selectedNode))
    if (this.events[titlegroup] === undefined) {
      this.events[titlegroup] = []
    }
    return this.events[titlegroup].push({hotkey, description})
  }

  addEvents (eventSpecs) {
    if ((eventSpecs != null ? eventSpecs.events : undefined) != null) {
      return Array.from(eventSpecs.events)
        .map((event) =>
          this.bind(event.hotkey, eventSpecs.title, event.description, event.callback))
    }
  }
}
