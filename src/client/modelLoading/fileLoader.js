import { Buffer } from "buffer"
import log from "loglevel"
import meshlib from "meshlib"
import stlParser from "stl-parser"

import * as modelCache from "./modelCache.js"
import * as Spinner from "../Spinner.js"

const readingString = "Reading file"
const uploadString = "Uploading file"
const loadedString = "File loaded!"
const errorString = "Import failed!"

export const onLoadFile = function (files, feedbackTarget, spinnerOptions) {
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

// Detect if an STL file is binary or ASCII
// Binary STL: 80 byte header + 4 byte face count + (50 bytes * face count)
// ASCII STL: starts with "solid" and contains proper ASCII keywords
//
// This is needed because stl-parser's built-in detection is flawed - it converts
// the entire file to a string and checks for "solid", "facet", and "vertex" keywords.
// Binary STL files often have "solid" in their 80-byte header and can accidentally
// contain byte sequences matching "facet"/"vertex", causing misdetection.
// Our approach uses the file size formula which is more reliable for binary detection.
function detectStlType (arrayBuffer) {
  const dataView = new DataView(arrayBuffer)

  // If file is too small to be a valid binary STL, assume ASCII
  if (arrayBuffer.byteLength < 84) {
    return "ascii"
  }

  // Read face count from bytes 80-83 (little-endian uint32)
  const faceCount = dataView.getUint32(80, true)

  // Calculate expected binary file size: 84 header bytes + 50 bytes per face
  const expectedBinarySize = 84 + faceCount * 50

  // If file size matches expected binary size (within tolerance for padding),
  // it's likely binary
  if (Math.abs(arrayBuffer.byteLength - expectedBinarySize) <= 1) {
    return "binary"
  }

  // Check if it looks like ASCII by checking for printable characters
  // in the first part of the file (after "solid" keyword)
  const bytes = new Uint8Array(arrayBuffer)
  let asciiCount = 0
  const checkLength = Math.min(1000, bytes.length)
  for (let i = 0; i < checkLength; i++) {
    // Printable ASCII or whitespace
    if ((bytes[i] >= 32 && bytes[i] <= 126) || bytes[i] === 9 || bytes[i] === 10 || bytes[i] === 13) {
      asciiCount++
    }
  }

  // If more than 95% of checked bytes are ASCII printable, likely ASCII format
  if (asciiCount / checkLength > 0.95) {
    return "ascii"
  }

  return "binary"
}

var handleLoadedFile = (feedbackTarget, filename, spinnerOptions) => function (event) {
  log.debug(`File ${filename} loaded, size: ${event.target.result.byteLength} bytes`)
  const fileContent = event.target.result

  return new Promise((resolve, reject) => {
    const stlType = detectStlType(fileContent)
    log.debug(`Detected STL type: ${stlType}`)

    // Convert ArrayBuffer to Buffer for the stl-parser library.
    // The library expects Buffer and has issues with ArrayBuffer/Uint8Array
    // when type is explicitly set.
    const stlBuffer = Buffer.from(fileContent)

    // For binary STL, we force the type to prevent the library's flawed auto-detection
    // which can incorrectly parse binary files as ASCII if the header contains
    // "solid", "facet", and "vertex" byte sequences.
    const parserOptions = stlType === "binary" ? { type: "binary" } : undefined

    const stlParserInstance = stlParser(stlBuffer, parserOptions)

    stlParserInstance.on("error", error => reject(error))

    // Track if we've already processed valid model data
    // The parser may emit multiple data events (parsed model + raw buffer)
    let modelProcessed = false

    stlParserInstance.on("data", (data) => {
      // Only process if this is a valid parsed model object with faces
      // Skip raw buffer data or subsequent emissions
      if (modelProcessed || !data?.faces || !Array.isArray(data.faces)) {
        return
      }

      modelProcessed = true
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

    // Explicitly start the stream flowing (needed for some stream polyfills)
    if (typeof stlParserInstance.resume === "function") {
      stlParserInstance.resume()
    }
  })
}
