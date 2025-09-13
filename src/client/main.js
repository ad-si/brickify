import $ from "jquery"
// Ensure Bootstrap plugins attach to the same jQuery instance used in the app
window.jQuery = window.$ = $
// Kick off loading Bootstrap (no top-level await to support legacy targets)
const bootstrapReady = import("bootstrap/dist/js/bootstrap.js")

import ZeroClipboard from "zeroclipboard"
import log from "loglevel"

import Bundle from "./bundle.js"

import globalConfig from "../common/globals.yaml"

import * as piwikTracking from "./piwikTracking.js"

if (process.env.NODE_ENV === "development") {
  log.enableAll()
}
else {
  log.setLevel("warn")
}

const commandFunctions = {
  initialModel (identifier) {
    piwikTracking.trackEvent(
      "trackEvent", "Editor", "StartWithInitialModel", identifier,
    )
    // load selected model
    log.debug("loading initial model")
    bundle.sceneManager.clearScene()
    return bundle.modelLoader.loadByIdentifier(identifier)
  },
}

const postInitCallback = function () {
  // look at url hash and run commands
  let {
    hash,
  } = window.location
  hash = hash.substring(1, hash.length)
  const commands = hash.split("+")
  let prom = Promise.resolve()
  const runCmd = (key, value) => () => Promise.resolve(commandFunctions[key](value))
  for (const cmd of Array.from(commands)) {
    const key = cmd.split("=")[0]
    const value = cmd.split("=")[1]
    if (commandFunctions[key] != null) {
      prom = prom.then(runCmd(key, value))
    }
  }

  if (commands.length === 0) {
    piwikTracking.trackEvent("Editor", "Start", "StartWithoutInitialModel")
  }

  // clear url hash after executing commands
  return window.location.hash = ""
}

var bundle = new Bundle(globalConfig)
bundle.init()
  .then(postInitCallback)

Promise.resolve($.get("/share"))
  .then(async (link) => {
    // Ensure Bootstrap plugins are ready before using tooltips
    await bootstrapReady
  // init share logic
    ZeroClipboard.config(
      {swfPath: "/node_modules/zeroclipboard/dist/ZeroClipboard.swf"})
    const url = document.location.origin + "/app?share=" + link
    $("#cmdShare")
      .tooltip({placement: "bottom"})
      .click(() => {
        bundle.saveChanges()
          .then(
            bootbox.dialog({
              title: "Share your work!",
              message: "<label for=\"shareUrl\">Via URL:</label> \
<input id=\"shareUrl\" class=\"form-control not-readonly\" \
type=\"text\" value=\"" + url + "\" onClick=\"this.select()\" readonly> \
<div id=\"copy-button\" class=\"btn btn-primary copy-button\" \
data-clipboard-text=\"" + url + '">Copy</div>',
            }),
          )
        const copyButton = $("#copy-button")
        const client = new ZeroClipboard(copyButton)

        return client.on("ready", _readyEvent => client.on("aftercopy", (_event) => {
          copyButton.html('Copied <span class="fa fa-check"></span>')
          return copyButton.addClass("btn-success")
        }))
      })

    // init direct help
    return $("#cmdHelp")
      .tooltip({placement: "bottom"})
      .click(() => bundle.ui.hotkeys.showHelp())
  })
