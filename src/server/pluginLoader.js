import fsp from "fs/promises"
import path from "path"
import winston from "winston"
import yaml from "js-yaml"

import PluginHooks from "../common/pluginHooks.js"
import packageJson from "../../package.json" with { type: "json"}

const log = winston.loggers.get("log")

// Load the hook list and initialize the pluginHook management
export const pluginHooks = new PluginHooks()

const __dirname = import.meta.dirname
const hooks = yaml.load(
  await fsp.readFile(path.join(__dirname, "pluginHooks.yaml"), "utf8")
)
pluginHooks.initHooks(hooks)

function initPluginInstance (pluginInstance) {
  if (typeof pluginInstance.init === "function") {
    pluginInstance.init()
  }
  return pluginHooks.register(pluginInstance)
}

async function loadPlugin (directory) {
  log.info(`Loading plugin "${directory}" …`)

  let instance
  try {
    instance = await import(`${directory}/${path.basename(directory)}.js`)
  }
  catch (error) {
    if (error.code !== "MODULE_NOT_FOUND") {
      throw error
    }
    return
  }

  const fullInstance = Object.assign(
    {},
    instance.default || instance,
    packageJson,
  )

  initPluginInstance(fullInstance)

  log.info(`Plugin ${fullInstance.name} loaded`)
}

// TODO: Maybe load plugins in parallel
export async function loadPlugins (directory) {
  const dirs = (await fsp.readdir(directory))
    .filter(dir => dir !== ".DS_Store" && dir !== "dummy")

  for (const dir of dirs) {
    await loadPlugin(path.resolve(__dirname, `../plugins/${dir}`))
  }
}
