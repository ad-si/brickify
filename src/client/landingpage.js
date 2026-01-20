import $ from "jquery"
window.jQuery = window.$ = $
// Init quickconvert after basic page functionality has been initialized

import Bundle from "./bundle.js"
import clone from "clone"
import * as fileLoader from "./modelLoading/fileLoader.js"
import * as fileDropper from "./modelLoading/fileDropper.js"

import globalConfig from "../common/globals.yaml"

// Set renderer size to fit to 3 bootstrap columns
globalConfig.staticRendererSize = true
globalConfig.staticRendererWidth = 388
globalConfig.staticRendererHeight = 300
globalConfig.buildUi = false
globalConfig.plugins.dummy = false
globalConfig.plugins.undo = false
globalConfig.plugins.coordinateSystem = false
globalConfig.plugins.legoBoard = false
globalConfig.plugins.editController = false
globalConfig.plugins.csg = false
globalConfig.colors.modelOpacity = globalConfig.colors.modelOpacityLandingPage

// disable wireframe and pipeline on landingpage
globalConfig.rendering.showShadowAndWireframe = false
globalConfig.rendering.usePipeline = false

// clone global config 2 times
const config1 = clone(globalConfig)
const config2 = clone(globalConfig)

// configure left bundle to only show model, disable lego instructions
config1.plugins.newBrickator = false
config1.plugins.legoInstructions = false

// configure right bundle to not show the model
config2.rendering.showModel = false

// configure right bundle to offer downloading lego instructions
config2.offerDownload = true
config2.downloadSettings = {
  testStrip: false,
  stl: false,
  lego: true,
  steps: 0,
}

// instantiate 2 brickify bundles
config1.renderAreaId = "renderArea1"
const bundle1 = new Bundle(config1)
var b1 = bundle1.init()
  .then(() => {
    const controls = bundle1.getControls()
    controls.animation.orbit({yawSpeed: -1 / 30})
    config2.renderAreaId = "renderArea2"
    const bundle2 = new Bundle(config2, controls)
    const b2 = bundle2.init()

    const loadAndConvert = function (identifier) {
      b1
        .then(() => bundle1.sceneManager.clearScene())
        .then(() => bundle1.loadByIdentifier(identifier))
        .then(() => $("#" + config1.renderAreaId)
          .css("backgroundImage", "none"))
      b2
        .then(() => bundle2.sceneManager.clearScene())
        .then(() => bundle2.loadByIdentifier(identifier))
        .then(() => $("#" + config2.renderAreaId)
          .css("backgroundImage", "none"))
      return $(".applink")
        .prop("href", `app#initialModel=${identifier}`)
    }

    // load and process model
    loadAndConvert("goggles")

    const fileLoadCallback = function (event) {
      const files = event.target.files != null ? event.target.files : event.dataTransfer.files
      if (files.length) {
        return fileLoader.onLoadFile(files, $("#loadButton")[0], {shadow: false})
          .then(loadAndConvert)
      }
    }

    fileDropper.init(fileLoadCallback)

    const fileInput = document.getElementById("fileInput")
    fileInput.addEventListener("change", (event) => {
      fileLoadCallback(event)
      return fileInput.value = ""
    })

    $(".dropper")
      .text("Drop an STL file")
  })
