import * as fileDropper from "../../modelLoading/fileDropper.js"
import * as fileLoader from "../../modelLoading/fileLoader.js"
import * as piwikTracking from "../../piwikTracking.js"

export default class LoadUi {
  constructor (workflowUi) {
    this.setEnabled = this.setEnabled.bind(this)
    this._initFileLoadHandler = this._initFileLoadHandler.bind(this)
    this.fileLoadHandler = this.fileLoadHandler.bind(this)
    this._checkReplaceModel = this._checkReplaceModel.bind(this)
    this.workflowUi = workflowUi
    this.$panel = $("#loadGroup")
    this._initFileLoadHandler()
  }

  setEnabled (enabled) {
    return this.$panel.find(".btn, .panel")
      .toggleClass("disabled", !enabled)
  }

  _initFileLoadHandler () {
    fileDropper.init(this.fileLoadHandler)

    return $("#fileInput")
      .on("change", event => {
        return this.fileLoadHandler(event)
          .then(() => {
            $("#fileInput")
              .val("")
            return this.workflowUi.hideMenuIfPossible()
          })
      })
  }

  fileLoadHandler (event) {
    const files = event.target.files != null ? event.target.files : event.dataTransfer.files
    return this._checkReplaceModel()
      .then(loadConfirmed => {
        if (!loadConfirmed) {
          return
        }
        piwikTracking.trackEvent("Editor", "LoadModel", files[0].name)
        const spinnerOptions = {
          length: 5,
          radius: 3,
          width: 2,
          shadow: false,
        }
        return fileLoader.onLoadFile(
          files,
          document.getElementById("loadButtonFeedback"),
          spinnerOptions,
        )
          .then(this.workflowUi.bundle.modelLoader.loadByIdentifier)
      })
  }

  _checkReplaceModel () {
    const question = "You already have a model in your scene. \
Loading the new model will replace the existing model!"

    return this.workflowUi.bundle.sceneManager.scene.then((scene) => {
      if (scene.nodes.length === 0) {
        return true
      }
      return new Promise(resolve => bootbox.confirm(question, resolve))
    })
  }
}
