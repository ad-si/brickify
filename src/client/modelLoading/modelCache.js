import $ from "jquery"
import { md5 } from "blueimp-md5"
import meshlib from "meshlib"
import log from "loglevel"

// #
//  ModelCache
//  Caches models and allows all Plugins to retrieve
//  cached models from the server
// #

// The cache of optimized model promises
const modelCache = {}

const exists = identifier => Promise.resolve(
  $.ajax("/model/" + identifier,
    {type: "HEAD"}),
)
  .catch((jqXHR) => {
    throw new Error(jqXHR.statusText)
  })
export { exists }

// sends the model to the server if the server hasn't got a model
// with the same identifier
const submitDataToServer = function (identifier, data) {
  const send = function () {
    const prom = Promise.resolve(
      $.ajax("/model/" + identifier, {
        data,
        type: "PUT",
        contentType: "application/octet-stream",
      }),
    )
      .catch((jqXHR) => {
        throw new Error(jqXHR.statusText)
      })
    prom.then(
      () => log.debug("Sent model to the server"),
      () => log.error("Unable to send model to the server"))
    return prom
  }
  return exists(identifier)
    .catch(send)
}

export const store = model => model
  .getBase64()
  .then((base64Model) => {
    const identifier = md5(base64Model)
    modelCache[identifier] = Promise.resolve(model)
    return submitDataToServer(identifier, base64Model)
      .then(() => identifier)
  })

// requests a mesh with the given identifier from the server
const requestDataFromServer = identifier => Promise.resolve($.get("/model/" + identifier))
  .catch((jqXHR) => {
    throw new Error(jqXHR.statusText)
  })

const buildModelPromise = identifier => requestDataFromServer(identifier)
  .then(base64Model => meshlib.Model
    .fromBase64(base64Model)
    .buildFacesFromFaceVertexMesh())


// Request an optimized mesh with the given identifier
// The mesh will be provided by the cache if present or loaded from the server
// if available.
export const request = identifier => modelCache[identifier] != null ? modelCache[identifier] : modelCache[identifier] = buildModelPromise(identifier)
