import samples from "../src/server/modelSamples.js"
import storage from "../src/server/modelStorage.js"

const exists = identifier => samples.exists(identifier)
  .catch(() => storage.exists(identifier))

module.exports.exists = function (request, response) {
  const {
    identifier,
  } = request.params

  return exists(identifier)
    .then(() => response.status(200)
      .send(identifier))
    .catch(() => response.status(404)
      .send(identifier))
}

const get = identifier => samples.get(identifier)
  .catch(() => storage.get(identifier))

module.exports.get = function (request, response) {
  const {
    identifier,
  } = request.params

  return get(identifier)
    .then((model) => {
      response.set("Content-Type", "application/octet-stream")
      return response.send(model)
    })
    .catch(() => response.status(404)
      .send(identifier))
}

module.exports.store = function (request, response) {
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
