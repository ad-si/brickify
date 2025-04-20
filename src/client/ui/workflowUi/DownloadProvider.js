import $ from "jquery"
import saveAs from "filesaver.js"
import JSZip from "jszip"
import log from "loglevel"

import Spinner from "../../Spinner.js"
import piwikTracking from "../../piwikTracking.js"


export default class DownloadProvider {
  constructor (bundle) {
    this.init = this.init.bind(this)
    this._createDownload = this._createDownload.bind(this)
    this._convertToZippableType = this._convertToZippableType.bind(this)
    this.bundle = bundle
  }

  init (stlButtonId, instructionsButtonId, exportUi, sceneManager) {
    this.exportUi = exportUi
    this.sceneManager = sceneManager
    this.$stlButton = $(stlButtonId)
    this.$stlButton.on("click", () => {
      const selNode = this.sceneManager.selectedNode
      if (selNode != null) {
        Spinner.startOverlay(this.$stlButton[0])
        this.$stlButton.addClass("disabled")
        return window.setTimeout(
          () => this._createDownload("stl", selNode),
          20,
        )
      }
    })

    this.$instructionsButton = $(instructionsButtonId)
    return this.$instructionsButton.on("click", () => {
      const selNode = this.sceneManager.selectedNode
      if (selNode != null) {
        Spinner.startOverlay(this.$instructionsButton[0])
        this.$instructionsButton.addClass("disabled")
        return window.setTimeout(
          () => this._createDownload("instructions", selNode),
          20,
        )
      }
    })
  }

  _createDownload (type, selectedNode) {
    const downloadOptions = {
      type,
      studRadius: this.exportUi.studRadius,
      holeRadius: this.exportUi.holeRadius,
    }

    if (type === "stl") {
      piwikTracking.trackEvent("EditorExport", "DownloadStlClick")
      piwikTracking.trackEvent(
        "EditorExport", "StudRadius", this.exportUi.studRadiusSelection,
      )
      piwikTracking.trackEvent(
        "EditorExport", "HoleRadius", this.exportUi.holeRadiusSelection,
      )
    }

    const promisesArray = this.bundle.pluginHooks.getDownload(
      selectedNode,
      downloadOptions,
    )

    return Promise
      .all(promisesArray)
      .then(resultsArray => {
        const files = this._collectFiles(resultsArray)

        // Stop showing spinner
        if (type === "instructions") {
          Spinner.stop(this.$instructionsButton[0])
          this.$instructionsButton.removeClass("disabled")
        }
        else {
          Spinner.stop(this.$stlButton[0])
          this.$stlButton.removeClass("disabled")
        }


        if (files.length === 1) {
          return saveAs(
            new Blob([files[0].data]),
            files[0].fileName.replace(/\.stl$/gi, "") + ".stl",
          )

        }
        else if (files.length > 1) {
          const zip = new JSZip()

          const downloadPromises = files.map(file => {
            return this._convertToZippableType(file)
          })

          return Promise
            .all(downloadPromises)
            .then((fileObjects) => {
              fileObjects.forEach(fileObject => zip.file(
                fileObject.fileName,
                fileObject.data,
              ))

              return saveAs(
                zip.generate({type: "blob"}),
                `brickify-${selectedNode.name}.zip`,
              )
            })

        }
        else {
          return bootbox.alert({
            title: "There is nothing to download at the moment",
            message: "This happens when your whole model \
is made out of LEGO \
and you have not selected anything to be 3D-printed. \
Use the Make 3D-print brush for that.",
          })
        }
      })
      .catch(error => log(error))
  }

  _collectFiles (array) {
    const files = []
    for (const entry of Array.from(array)) {
      if (entry == null) {
        continue
      }
      if (Array.isArray(entry)) {
        for (const subEntry of Array.from(entry)) {
          if (subEntry.fileName.length > 0) {
            files.push(subEntry)
          }
        }
      }
      else if (entry.fileName.length > 0) {
        files.push(entry)
      }
    }
    return files
  }


  _convertToZippableType ({data, fileName}) {
    switch (false) {
      case !(data instanceof Blob):
        return this._arrayBufferFromBlob(data, fileName, options)

      case !(data instanceof ArrayBuffer):
        return Promise.resolve({
          data,
          fileName,
          options: {
            binary: true,
          },
        })

      case (typeof data !== "string") && !(data instanceof String):
        return Promise.resolve({
          data,
          fileName,
          options: {
            binary: false,
          },
        })
      default:
        return log.warn(`No conversion method found for file ${fileName}`)
    }
  }


  _arrayBufferFromBlob (blob, fileName) {
    const reader = new FileReader()
    return new Promise((resolve, reject) => {
      reader.onload = () => resolve({
        data: reader.result,
        fileName,
        options: {
          binary: true,
        },
      })
      reader.onerror = reject
      reader.onabort = reject
      return reader.readAsArrayBuffer(blob)
    })
  }
}
