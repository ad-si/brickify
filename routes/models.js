import * as modelSamples from "../src/server/modelSamples.js"
import * as storage from "../src/server/modelStorage.js"

const existsIden = identifier => modelSamples.exists(identifier)
  .catch(() => storage.exists(identifier))

export function exists (request, response) {
  const {
    identifier,
  } = request.params

  return existsIden(identifier)
    .then(() => response.status(200)
      .send(identifier))
    .catch(() => response.status(404)
      .send(identifier))
}

const getIden = identifier => modelSamples.get(identifier)
  .catch(() => storage.get(identifier))

export function get (request, response) {
  const {
    identifier,
  } = request.params

  return getIden(identifier)
    .then((model) => {
      response.set("Content-Type", "application/octet-stream")
      return response.send(model)
    })
    .catch(() => response.status(404)
      .send(identifier))
}

export function store (request, response) {
  const {
    identifier,
  } = request.params
  const model = request.body

  return storage.store(identifier, model)
    .then(() => response.status(200)
      .send(identifier))
    .catch(() => response.status(500)
      .send("Model could not be stored."))
}
