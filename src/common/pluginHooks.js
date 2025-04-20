/*
  *Plugin Hook implementation#
*/

export default class PluginHooks {
  constructor () {
    // list of all hooks
    this.hooks = []
    // list of all hooks and their registered callbacks
    this.lists = []
  }

  // **check if a plugin provides a named hook method**
  hasHook (plugin, hook) {
    return typeof plugin[hook] === "function"
  }

  // **call the plugin's hook if provided with the passed arguments**
  call (plugin, hook, ...args) {
    if (this.hasHook(plugin, hook)) {
      return plugin[hook](...Array.from(args || []))
    }
  }

  // ***
  // ##Functions for plugin loaders only##

  /*
    **initialize the hook-list.**

    It will create an empty list of callbacks for each hook in `lists` and
    add a function to `module.exports` with the hook's name to be called by the
    modules that uses the hook.

    E.g. if `"foo"` is defined in the list of hooks above, there will be the
    method `module.exports.foo(args...)` with splat arguments that are passed
    to all registered callbacks, that is all plugins that provide a method named
    `foo`.
  */
  initHooks (hookList) {
    let hook
    this.hooks = hookList
    for (hook of Array.from(this.hooks)) {
      this.lists[hook] = []
    }
    return (() => {
      const result = []
      for (hook of Array.from(this.hooks)) {
        result.push(this[hook] =
          (hook => function (...args) {
            return Array.from(this.lists[hook])
              .map((callback) => callback(...Array.from(args || [])))
          })(hook))
      }
      return result
    })()
  }

  // **register a plugin for all the hooks it provides**
  register (plugin) {
    return Array.from(this.hooks)
      .map((hook) => this.registerHook(plugin, hook))
  }

  // **register a plugin for a specific hook if provided**
  registerHook (plugin, hook) {
    if (this.hasHook(plugin, hook)) {
      return this.lists[hook].push(plugin[hook])
    }
  }

  // **get all callbacks that are registered for a specific hook**
  get (hook) {
    return this.lists[hook]
  }

  // **unregister a plugin for all hooks it was registered for**
  unregister (plugin) {
    return Array.from(this.hooks)
      .map((hook) => this.unregisterHook(plugin, hook))
  }

  // **unregister a plugin for a specific hook if provided and registered**
  unregisterHook (plugin, hook) {
    if (this.hasHook(plugin, hook)) {
      const index = this.lists[hook].indexOf(plugin[hook])
      if (index !== -1) {
        return this.lists[hook].splice(index, 1)
      }
    }
  }
}
