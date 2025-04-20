import PluginLoader from "../client/pluginLoader.js"
import Ui from "./ui/ui.js"
import Renderer from "./rendering/Renderer.js"
import ModelLoader from "./modelLoading/modelLoader.js"
import SceneManager from "./sceneManager.js"
import Spinner from "./Spinner.js"

import SyncObject from "../common/sync/syncObject.js"
SyncObject.dataPacketProvider = require("./sync/dataPackets.js")
import Node from "../common/project/node.js"
Node.modelProvider = require("./modelLoading/modelCache.js")

import DownloadUi from "./ui/workflowUi/DownloadUi.js"

/*
 * @class Bundle
 */
export default class Bundle {
  constructor (globalConfig, controls) {
    this.init = this.init.bind(this)
    this.getPlugin = this.getPlugin.bind(this)
    this.getControls = this.getControls.bind(this)
    this.loadByIdentifier = this.loadByIdentifier.bind(this)
    this.globalConfig = globalConfig
    Spinner.startOverlay(document.getElementById(this.globalConfig.renderAreaId))
    this.pluginLoader = new PluginLoader(this)
    this.pluginHooks = this.pluginLoader.pluginHooks
    this.modelLoader = new ModelLoader(this)
    this.sceneManager = new SceneManager(this)
    this.renderer = new Renderer(this.pluginHooks, this.globalConfig, controls)
    this.pluginInstances = this.pluginLoader.loadPlugins()
    if (this.globalConfig.buildUi) {
      this.ui = new Ui(this)
    }
    if (this.globalConfig.offerDownload) {
      this.exportUi = new DownloadUi(this)
    }
  }

  init () {
    this.pluginLoader.initPlugins()
    if (this.ui != null) {
      this.ui.init()
    }
    this.renderer.initControls()
    return this.sceneManager.init()
      .then(() => Spinner.stop(document.getElementById(this.globalConfig.renderAreaId)))
  }

  getPlugin (name) {
    for (const p of Array.from(this.pluginInstances)) {
      if (p.name === name) {
        return p
      }
    }
    return null
  }

  getControls () {
    return this.renderer.getControls()
  }

  loadByIdentifier (identifier) {
    if (this.exportUi != null) {
      this.exportUi.setEnabled(false)
    }
    return this.modelLoader.loadByIdentifier(identifier)
      .then(() => {
        return this.exportUi != null ? this.exportUi.setEnabled(true) : undefined
      })
  }
}
