/*
 * @module pluginLoader
 */

// Load the hook list and initialize the pluginHook management
import THREE from "three"

import hooks from "./pluginHooks.yaml"
import PluginHooks from "../common/pluginHooks.js"

export default class PluginLoader {
  constructor (bundle) {
    this.initPlugins = this.initPlugins.bind(this)
    this.bundle = bundle
    this.pluginHooks = new PluginHooks()
    this.pluginHooks.initHooks(hooks)
    this.globalConfig = this.bundle.globalConfig
  }

  _loadPlugin (PluginClass, packageData) {
    const instance = new PluginClass()

    for (const key of Object.keys(packageData || {})) {
      const value = packageData[key]
      instance[key] = value
    }

    return instance
  }

  _initPlugin (instance) {
    let threeNode
    if (this.pluginHooks.hasHook(instance, "init")) {
      instance.init(this.bundle)
    }

    if (this.pluginHooks.hasHook(instance, "init3d")) {
      threeNode = new THREE.Object3D()
      threeNode.associatedPlugin = instance
      instance.init3d(threeNode)
    }

    this.pluginHooks.register(instance)

    if (threeNode != null) {
      return this.bundle.renderer.addToScene(threeNode)
    }
  }

  initPlugins () {
    return Array.from(this.pluginInstances)
      .map((plugin) =>
        this._initPlugin(plugin))
  }

  // Since browserify.js does not support dynamic require
  // all plugins must be explicitly written down
  loadPlugins () {
    this.pluginInstances = []

    if (this.globalConfig.plugins.dummy) {
      this.pluginInstances.push(this._loadPlugin(
        require("../plugins/dummy"),
        require("../plugins/dummy/package.json"),
      ),
      )
    }
    if (this.globalConfig.plugins.undo) {
      this.pluginInstances.push(this._loadPlugin(
        require("../plugins/undo"),
        require("../plugins/undo/package.json"),
      ),
      )
    }
    if (this.globalConfig.plugins.coordinateSystem) {
      this.pluginInstances.push(this._loadPlugin(
        require("../plugins/coordinateSystem"),
        require("../plugins/coordinateSystem/package.json"),
      ),
      )
    }
    if (this.globalConfig.plugins.nodeVisualizer) {
      this.pluginInstances.push(this._loadPlugin(
        require("../plugins/nodeVisualizer"),
        require("../plugins/nodeVisualizer/package.json"),
      ),
      )
    }
    if (this.globalConfig.plugins.legoBoard) {
      this.pluginInstances.push(this._loadPlugin(
        require("../plugins/legoBoard"),
        require("../plugins/legoBoard/package.json"),
      ),
      )
    }
    if (this.globalConfig.plugins.newBrickator) {
      this.pluginInstances.push(this._loadPlugin(
        require("../plugins/newBrickator"),
        require("../plugins/newBrickator/package.json"),
      ),
      )
    }
    if (this.globalConfig.plugins.fidelityControl) {
      this.pluginInstances.push(this._loadPlugin(
        require("../plugins/fidelityControl"),
        require("../plugins/fidelityControl/package.json"),
      ),
      )
    }
    if (this.globalConfig.plugins.editController) {
      this.pluginInstances.push(this._loadPlugin(
        require("../plugins/editController"),
        require("../plugins/editController/package.json"),
      ),
      )
    }
    if (this.globalConfig.plugins.csg) {
      this.pluginInstances.push(this._loadPlugin(
        require("../plugins/csg"),
        require("../plugins/csg/package.json"),
      ),
      )
    }
    if (this.globalConfig.plugins.legoInstructions) {
      this.pluginInstances.push(this._loadPlugin(
        require("../plugins/legoInstructions"),
        require("../plugins/legoInstructions/package.json"),
      ),
      )
    }

    return this.pluginInstances
  }
}
