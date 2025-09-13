import $ from "jquery"
window.jQuery = window.$ = $
import * as piwikTracking from "./piwikTracking.js"

// Init quickconvert after basic page functionality has been initialized

import Bundle from "./bundle.js"
import clone from "clone"
import * as fileLoader from "./modelLoading/fileLoader.js"
import * as fileDropper from "./modelLoading/fileDropper.js"
import * as modelCache from "./modelLoading/modelCache.js"

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

    const dropAndInputCallback = function (event) {
      const files = event.target.files != null ? event.target.files : event.dataTransfer.files
      if (files.length) {
        piwikTracking.trackEvent("Landingpage", "LoadModel", files[0].name)
        return fileLoader.onLoadFile(files, $("#loadButton")[0], {shadow: false})
          .then(loadAndConvert)
      }
      else {
        const identifier = event.dataTransfer.getData("text/plain")
        piwikTracking.trackEvent("Landingpage", "LoadModelFromImage", identifier)
        return modelCache.exists(identifier)
          .then(() => loadAndConvert(identifier))
          .catch(() => bootbox.alert({
            title: "This is not a valid model!",
            message: "You can only drop stl files or our example images.",
          }))
      }
    }

    fileDropper.init(dropAndInputCallback)

    const fileInput = document.getElementById("fileInput")
    fileInput.addEventListener("change", (event) => {
      dropAndInputCallback(event)
      return fileInput.value = ""
    })

    $(".dropper")
      .text("Drop an stl file")
    return $("#preview img, #preview a")
      .on( "dragstart",
        e => e.originalEvent.dataTransfer.setData(
          "text/plain",
          e.originalEvent.target.getAttribute("data-identifier"),
        ))
  })
