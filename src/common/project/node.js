import SyncObject from "../sync/syncObject.js"

/*
 * A node is an element in a scene that represents a model.
 *
 * @class Node
 */
export default class Node extends SyncObject {
  static initClass () {

    this.modelProvider = null
  }
  constructor (param) {
    super(arguments[0])
    this._isTransient = this._isTransient.bind(this)
    this.getPluginData = this.getPluginData.bind(this)
    this.storePluginData = this.storePluginData.bind(this)
    this.setModelIdentifier = this.setModelIdentifier.bind(this)
    this.getModelIdentifier = this.getModelIdentifier.bind(this)
    this.getModel = this.getModel.bind(this)
    this.setName = this.setName.bind(this)
    this.getName = this.getName.bind(this)
    this.setPosition = this.setPosition.bind(this)
    this.getPosition = this.getPosition.bind(this)
    this.setRotation = this.setRotation.bind(this)
    this.getRotation = this.getRotation.bind(this)
    this.setScale = this.setScale.bind(this)
    this.getScale = this.getScale.bind(this)
    this.setTransform = this.setTransform.bind(this)
    this.getTransform = this.getTransform.bind(this)
    this._setTransform = this._setTransform.bind(this)
    if (param == null) {
      param = {}
    }
    const {name, modelIdentifier, transform} = param
    this.transientProperties = []
    this.name = name != null ? name : null
    this.modelIdentifier = modelIdentifier != null ? modelIdentifier : null
    this.transform = {}
    this._setTransform(transform)
  }

  _isTransient (key) {
    return Array.from(this.transientProperties)
      .includes(key) || super._isTransient(key)
  }

  getPluginData (key) {
    return this.done(() => this[key])
  }

  storePluginData (key, data, transient) {
    if (transient == null) {
      transient = true
    }
    return this.next(() => {
      this[key] = data
      if (transient && !Array.from(this.transientProperties)
        .includes(key)) {
        return this.transientProperties.push(key)
      }
      else if (!transient && Array.from(this.transientProperties)
        .includes(key)) {
        const index = this.transientProperties.indexOf(key)
        return this.transientProperties.splice(index, 1)
      }
    })
  }

  setModelIdentifier (identifier) {
    return this.next(() => {
      return this.modelIdentifier = identifier
    })
  }

  getModelIdentifier () {
    return this.done(() => this.modelIdentifier)
  }

  getModel () {
    return this.done(() => Node.modelProvider.request(this.modelIdentifier))
  }

  setName (name) {
    return this.next(() => {
      return this.name = name
    })
  }

  getName () {
    const _getName = () => {
      if (this.name != null) {
        return this.name
      }
      else {
        return `Node ${this.id}`
      }
    }
    return this.done(_getName)
  }

  setPosition (position) {
    return this.setTransform({position})
  }

  getPosition () {
    return this.done(() => this.transform.position)
  }

  setRotation (rotation) {
    return this.setTransform({rotation})
  }

  getRotation () {
    return this.done(() => this.transform.rotation)
  }

  setScale (scale) {
    return this.setTransform({scale})
  }

  getScale () {
    return this.done(() => this.transform.scale)
  }

  setTransform (param) {
    if (param == null) {
      param = {}
    }
    const {position, rotation, scale} = param
    const args = arguments
    return this.next(() => this._setTransform(...Array.from(args || [])))
  }

  getTransform () {
    return this.done(() => this.transform)
  }

  _setTransform (param) {
    if (param == null) {
      param = {}
    }
    const {position, rotation, scale} = param
    this.transform.position = position || this.transform.position || {x: 0, y: 0, z: 0}
    this.transform.rotation = rotation || this.transform.rotation || {x: 0, y: 0, z: 0}
    return this.transform.scale = scale || this.transform.scale || {x: 1, y: 1, z: 1}
  }
}
Node.initClass()
