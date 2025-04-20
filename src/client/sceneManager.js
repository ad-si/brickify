import Project from "../common/project/project.js"

/*
 * @class SceneManager
 */
export default class SceneManager {
  constructor (bundle) {
    this.init = this.init.bind(this)
    this.getHotkeys = this.getHotkeys.bind(this)
    this._notify = this._notify.bind(this)
    this.add = this.add.bind(this)
    this._addNodeToScene = this._addNodeToScene.bind(this)
    this.remove = this.remove.bind(this)
    this.clearScene = this.clearScene.bind(this)
    this.select = this.select.bind(this)
    this.deselect = this.deselect.bind(this)
    this._deleteCurrentNode = this._deleteCurrentNode.bind(this)
    this.bundle = bundle
    this.selectedNode = null
    this.pluginHooks = this.bundle.pluginHooks
    this.project = Project.load()
    this.scene = this.project.then(project => project.getScene())
  }

  init () {
    return this.scene
      .then(scene => scene.getNodes())
      .then(nodes => Array.from(nodes)
        .map((node) => this._notify("onNodeAdd", node)))
  }

  getHotkeys () {
    return {
      title: "Scene",
      events: [
        this._getDeleteHotkey(),
      ],
    }
  }

  _notify (hook, node) {
    return Promise.all(this.pluginHooks[hook](node))
      .then(() => __guardMethod__(this.bundle.ui != null ? this.bundle.ui.workflowUi : undefined, hook, (o, m) => o[m](node)))
  }

  //
  // Administration of nodes
  //

  add (node) {
    return this.scene
      .then(scene => {
        if (scene.nodes.length > 0) {
          this.remove(scene.nodes[0])
        }
        return this._addNodeToScene(node)
      })
  }

  _addNodeToScene (node) {
    return this.scene
      .then(scene => scene.addNode(node))
      .then(() => this._notify("onNodeAdd", node))
      .then(() => this.select(node))
  }

  remove (node) {
    return this.scene
      .then(scene => scene.removeNode(node))
      .then(() => this._notify("onNodeRemove",  node))
      .then(() => {
        if (node === this.selectedNode) {
          return this.deselect(node)
        }
      })
  }

  clearScene () {
    return this.scene
      .then(scene => scene.getNodes())
      .then(nodes => Array.from(nodes)
        .map((node) => this.remove(node)))
  }

  //
  // Selection of nodes
  //

  select (selectedNode) {
    this.selectedNode = selectedNode
    this._notify("onNodeSelect", this.selectedNode)
  }

  deselect () {
    if (this.selectedNode != null) {
      this._notify("onNodeDeselect", this.selectedNode)
      this.selectedNode = null
    }
  }

  //
  // Deletion of nodes
  //

  _deleteCurrentNode () {
    if (this.bootboxOpen) {
      return
    }
    if (this.selectedNode == null) {
      return
    }

    this.bootboxOpen = true
    return this.selectedNode.getName()
      .then(name => {
        const question = `Do you really want to delete ${name}?`
        return bootbox.confirm(question, result => {
          this.bootboxOpen = false
          if (result) {
            this.remove(this.selectedNode)
            return this.deselect()
          }
        })
      })
  }

  _getDeleteHotkey () {
    return {
      hotkey: "del",
      description: "delete selected model",
      callback: this._deleteCurrentNode,
    }
  }
}

function __guardMethod__ (obj, methodName, transform) {
  if (typeof obj !== "undefined" && obj !== null && typeof obj[methodName] === "function") {
    return transform(obj, methodName)
  }
  else {
    return undefined
  }
}
