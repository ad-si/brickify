import fsp from "fs/promises"
import path from "path"
import winston from "winston"
import yaml from "js-yaml"

import PluginHooks from "../common/pluginHooks.js"
import packageJson from "../../package.json" with { type: "json"}
import type { Plugin } from "../types/plugin.js"

interface NodeError extends Error {
  code?: string;
}

const log = winston.loggers.get("log")

// Load the hook list and initialize the pluginHook management
export const pluginHooks = new PluginHooks()

const __dirname = import.meta.dirname
const hooks = yaml.load(
  await fsp.readFile(path.join(__dirname, "pluginHooks.yaml"), "utf8")
) as string[]
pluginHooks.initHooks(hooks)

function initPluginInstance (pluginInstance: Plugin): void {
  if (typeof pluginInstance.init === "function") {
    pluginInstance.init()
  }
  pluginHooks.register(pluginInstance)
}

async function loadPlugin (directory: string): Promise<void> {
  log.info(`Loading plugin "${directory}" …`)

  let instance
  try {
    instance = await import(`${directory}/${path.basename(directory)}.js`)
  }
  catch (error) {
    if ((error as NodeError).code !== "MODULE_NOT_FOUND") {
      throw error
    }
    return
  }

  // Merge the plugin module with package.json to ensure name/version are present
  const fullInstance = Object.assign(
    {},
    instance.default || instance,
    { name: packageJson.name, version: packageJson.version },
  ) as Plugin

  initPluginInstance(fullInstance)

  log.info(`Plugin ${fullInstance.name} loaded`)
}

// TODO: Maybe load plugins in parallel
export async function loadPlugins (directory: string): Promise<void> {
  const dirs = (await fsp.readdir(directory))
    .filter(dir => dir !== ".DS_Store" && dir !== "dummy")

  for (const dir of dirs) {
    await loadPlugin(path.resolve(__dirname, `../plugins/${dir}`))
  }
}
