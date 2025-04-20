/*
 * @module modelLoader
 */

import log from "loglevel"

import modelCache from "./modelCache.js"
import Node from "../../common/project/node.js"

/*
 * @class ModelLoader
 */
export default class ModelLoader {
  constructor (bundle) {
    this.loadByIdentifier = this.loadByIdentifier.bind(this)
    this._load = this._load.bind(this)
    this.bundle = bundle
  }

  loadByIdentifier (identifier) {
    return modelCache
      .request(identifier)
      .then(model => this._load(model, identifier))
      .catch((error) => {
        log.error(`Could not load model ${identifier}`)
        return log.error(error.stack)
      })
  }

  _load (model, identifier) {
    return model
      .done()
      .then(() => {
        const name = model.model.name || model.model.fileName || identifier
        return this._addModelToScene(name, identifier, model)
      })
  }

  // adds a new model to the state
  _addModelToScene (name, identifier, model) {
    return model
      .getAutoAlignMatrix()
      .then(matrix => {
        const node = new Node({
          name,
          modelIdentifier: identifier,
          transform: {
            position: {
              x: matrix[0][3],
              y: matrix[1][3],
              z: matrix[2][3],
            },
          }})

        return this.bundle.sceneManager.add(node)
      })
  }
}
