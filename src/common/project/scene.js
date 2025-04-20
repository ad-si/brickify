import SyncObject from "../sync/syncObject.js"
import Node from "./node.js"

/*
 * A scene is a collection of nodes and settings and represents a state of a
 * project.
 *
 * @class Scene
 */
export default class Scene extends SyncObject {
  constructor () {
    super(arguments[0])
    this._modify = this._modify.bind(this)
    this._loadSubObjects = this._loadSubObjects.bind(this)
    this.addNode = this.addNode.bind(this)
    this.getNodes = this.getNodes.bind(this)
    this.removeNode = this.removeNode.bind(this)
    this.nodes = []
    this._modify("Scene creation")
  }

  _modify (cause) {
    return this.lastModified = {
      date: Date.now(),
      cause,
    }
  }

  _loadSubObjects () {
    const _loadNode = reference => Node.from(reference)
    return Promise.all(this.nodes.map(_loadNode))
      .then(nodes => {
        return this.nodes = nodes
      })
  }

  addNode (node) {
    const _addNode = () => {
      return node.getName()
        .then(name => {
          this.nodes.push(node)
          return this._modify(`Node \"${name}\" added`)
        })
    }
    return this.next(_addNode)
  }

  getNodes () {
    return this.done(() => this.nodes)
  }

  removeNode (node) {
    const _removeNode = () => {
      return node.getName()
        .then(name => {
          let index
          if ((index = this.nodes.indexOf(node)) !== -1) {
            this.nodes.splice(index, 1)
            return this._modify(`Node \"${name}\" removed`)
          }
        })
    }
    return this.next(_removeNode)
  }
}
