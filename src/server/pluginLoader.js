// File system support
import fs from "fs"
// Manipulate platform-independent path strings
import path from "path"
// Colorful logger for console
import winston from "winston"
const log = winston.loggers.get("log")
// Load the hook list and initialize the pluginHook management
import yaml from "js-yaml"

import PluginHooks from "../common/pluginHooks"
const pluginHooks = new PluginHooks()
module.exports.pluginHooksInstance = pluginHooks

const hooks = yaml.load(fs.readFileSync(path.join(__dirname, "pluginHooks.yaml")))
pluginHooks.initHooks(hooks)

const initPluginInstance = function (pluginInstance) {
  if (typeof pluginInstance.init === "function") {
    pluginInstance.init()
  }
  return pluginHooks.register(pluginInstance)
}

const loadPlugin = function (directory) {
  let instance
  try {
    instance = require(directory)

  }
  catch (error) {
    if (error.code !== "MODULE_NOT_FOUND") {
      throw error
    }
    return
  }

  import object from path.join(directory, "package.json")
  for (const key of Object.keys(object || {})) {
    const value = object[key]
    instance[key] = value
  }

  initPluginInstance(instance)
  return log.info(`Plugin ${instance.name} loaded`)
}


module.exports.loadPlugins = directory => fs.readdir(directory, (error, dirs) => {
  if (error) {
    throw error
  }
  return dirs.forEach(dir => loadPlugin(path.resolve(__dirname, "../plugins/" + dir)))
})
