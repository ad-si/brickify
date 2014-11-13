###
  #Plugin Hook implementation#
###

# list of all hooks
hooks = []

# list of all hooks and their registered callbacks
lists = []

# **check if a plugin provides a named hook method**
hasHook = (plugin, hook) ->
	typeof plugin[hook] is 'function'

# **call the plugin's hook if provided with the passed arguments**
module.exports.call = (plugin, hook, args...) ->
	plugin[hook] args... if hasHook plugin, hook

# ***
# ##Functions for plugin loaders only##

###
  **initialize the hook-list.**

  It will create an empty list of callbacks for each hook in `lists` and
  add a function to `module.exports` with the hook's name to be called by the
  modules that uses the hook.

  E.g. if `"foo"` is defined in the list of hooks above, there will be the
  method `module.exports.foo(args...)` with splat arguments that are passed
  to all registered callbacks, that is all plugins that provide a method named
  `foo`.
###
module.exports.initHooks = (hookList) ->
	hooks = hookList
	lists[hook] = [] for hook in hooks
	for hook in hooks
		module.exports[hook] =
			do (hook) ->
				(args...) -> callback args... for callback in lists[hook]

# **register a plugin for all the hooks it provides**
module.exports.register = (plugin) ->
	registerHook plugin, hook for hook in hooks

# **register a plugin for a specific hook if provided**
registerHook = (plugin, hook) ->
	lists[hook].push plugin[hook] if hasHook plugin, hook

# **unregister a plugin for all hooks it was registered for**
module.exports.unregister = (plugin) ->
	unregisterHook plugin, hook for hook in hooks

# **unregister a plugin for a specific hook if provided and registered**
unregisterHook = (plugin, hook) ->
	if hasHook plugin, hook
		index = lists[hook].indexOf plugin[hook]
		lists[hook].splice index, 1 if index != -1
