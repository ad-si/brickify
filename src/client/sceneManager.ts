import Project from "../common/project/project.js"
import type Bundle from "./bundle.js"
import type Node from "../common/project/node.js"

/*
 * @class SceneManager
 */
export default class SceneManager {
  bundle: Bundle
  selectedNode: Node | null
  pluginHooks: any
  project: Promise<any>
  scene: Promise<any>
  bootboxOpen?: boolean

  constructor (bundle: Bundle) {
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
    this.project = (Project as any).load()
    this.scene = this.project.then(project => project.getScene())
  }

  init () {
    return this.scene
      .then((scene: any) => scene.getNodes())
      .then((nodes: any) => Array.from(nodes)
        .map((node: any) => this._notify("onNodeAdd", node as Node)))
  }

  getHotkeys () {
    return {
      title: "Scene",
      events: [
        this._getDeleteHotkey(),
      ],
    }
  }

  _notify (hook: string, node: Node) {
    return Promise.all(this.pluginHooks[hook](node))
      .then(() => __guardMethod__((this.bundle.ui as any)?.workflowUi, hook, (o, m) => o[m](node)))
  }

  //
  // Administration of nodes
  //

  add (node: Node) {
    return this.scene
      .then((scene: any) => {
        if (scene.nodes.length > 0) {
          void this.remove(scene.nodes[0])
        }
        return this._addNodeToScene(node)
      })
  }

  _addNodeToScene (node: Node) {
    return this.scene
      .then((scene: any) => scene.addNode(node))
      .then(() => this._notify("onNodeAdd", node))
      .then(() => { this.select(node) })
  }

  remove (node: Node) {
    return this.scene
      .then((scene: any) => scene.removeNode(node))
      .then(() => this._notify("onNodeRemove",  node))
      .then(() => {
        if (node === this.selectedNode) {
          this.deselect()
          return
        }
      })
  }

  clearScene () {
    return this.scene
      .then((scene: any) => scene.getNodes())
      .then((nodes: any) => Array.from(nodes)
        .map((node: any) => this.remove(node as Node)))
  }

  //
  // Selection of nodes
  //

  select (selectedNode: Node) {
    this.selectedNode = selectedNode
    void this._notify("onNodeSelect", this.selectedNode)
  }

  deselect () {
    if (this.selectedNode != null) {
      void this._notify("onNodeDeselect", this.selectedNode)
      this.selectedNode = null
    }
  }

  //
  // Deletion of nodes
  //

  _deleteCurrentNode (): void {
    if (this.bootboxOpen) {
      return
    }
    if (this.selectedNode == null) {
      return
    }

    this.bootboxOpen = true
    void this.selectedNode.getName()
      .then((name: any) => {
        const question = `Do you really want to delete ${name}?`
        return bootbox.confirm(question, result => {
          this.bootboxOpen = false
          if (result) {
            void this.remove(this.selectedNode!)
            this.deselect()
          return
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

function __guardMethod__ (obj: any, methodName: string, transform: (o: any, m: string) => any) {
  if (typeof obj !== "undefined" && obj !== null && typeof obj[methodName] === "function") {
    return transform(obj, methodName)
  }
  else {
    return undefined
  }
}
