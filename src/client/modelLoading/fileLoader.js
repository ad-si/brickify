import log from "loglevel"
import meshlib from "meshlib"
import stlParser from "stl-parser"

import modelCache from "./modelCache.js"
import Spinner from "../Spinner.js"

const readingString = "Reading file"
const uploadString = "Uploading file"
const loadedString = "File loaded!"
const errorString = "Import failed!"

module.exports.onLoadFile = function (files, feedbackTarget, spinnerOptions) {
  if (files.length < 1) {
    return Promise.reject()
  }

  const file = files[0]
  if (!file.name.toLowerCase()
    .endsWith(".stl")) {
    bootbox.alert({
      title: "Your file does not have the right format!",
      message: "Only .stl files are supported at the moment. \
We are working on adding more file formats",
    })
    return Promise.reject("Wrong file format")
  }

  return loadFile(feedbackTarget, file, spinnerOptions)
    .then(handleLoadedFile(feedbackTarget, file.name, spinnerOptions))
    .catch((error) => {
      bootbox.alert({
        title: "Import failed",
        message:
          `<p>Your file contains errors that we could not fix.</p> \
<p>Details:</br> \
<small>${error.message}</small> \
</p>`,
      })
      feedbackTarget.innerHTML = errorString
      return log.error(error)
    })
}

var loadFile = function (feedbackTarget, file, spinnerOptions) {
  feedbackTarget.innerHTML = readingString
  Spinner.start(feedbackTarget, spinnerOptions)
  const reader = new FileReader()
  return new Promise((resolve, reject) => {
    reader.onload = resolve
    reader.onerror = reject
    reader.onabort = reject
    return setTimeout(() => reader.readAsArrayBuffer(file))
  })
}

var handleLoadedFile = (feedbackTarget, filename, spinnerOptions) => function (event) {
  log.debug(`File ${filename} loaded`)
  const fileContent = event.target.result

  return new Promise((resolve, reject) => {

    const stlParserInstance = stlParser(fileContent)

    stlParserInstance.on("error", error => reject(error))

    return stlParserInstance.on("data", (data) => {
      const model = meshlib.Model.fromObject({mesh: data})

      return model
        .setFileName(filename)
        .setName(filename)
        .calculateNormals()
        .buildFaceVertexMesh()
        .done()
        .then(() => {
          Spinner.stop(feedbackTarget)
          feedbackTarget.innerHTML = uploadString
          Spinner.start(feedbackTarget, spinnerOptions)
          return modelCache.store(model)
        })
        .then((md5hash) => {
          Spinner.stop(feedbackTarget)
          feedbackTarget.innerHTML = loadedString
          return resolve(md5hash)
        })
        .catch(error => reject(error))
    })
  })
}
