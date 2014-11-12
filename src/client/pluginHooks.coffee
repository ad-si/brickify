###
  #Plugin API#

  Client-side plugins can provide the following hooks to interact with lowfab.

  The hooks must exist at load-time. Hooks that are added later during
  run-time will not be called.

  See [dummyPlugin](plugins/dummy/dummy.html) for a example implementation
  and further documentation of the plugin API.
###

@hooks = [
	#  ##Plugin Initialization##
	#
	#  The [pluginLoader](pluginLoader.html) will call each plugin's `init` method
	#  (if provided) after loading the plugin. It is the first method to be called
	#  and provides access to the [global configuration](globals.html), the
	#  [state synchronization module](statesync.html) and the [ui module](ui.html).
	"init"

	#  ##State synchronization##
	#
	#  The [state synchronization module](statesync.html) will call each plugin's
	#  `updateState` method (if provided) whenever the current state changes
	#  due to user input or calculation results on either server or client side.
	#
	#  The hook provides both the delta to the previous state and the new complete
	#  state as arguments.
	"updateState"

	#  ##3D scene initialization##
	#
	#  Each plugin that provides a `init3D` method is able to initialize its 3D
	#  rendering there and receives a three.js node as argument.
	#
	#  If the plugin needs its node for later use it has to store it in `init3D`
	#  because it won't be handed the node again later.
	"init3D"

	#  ##3D scene update and animation##
	#
	#  On each render frame the [renderer](render.html) will call the `update3D`
	#  method of all plugins that provide it. There are no arguments passed.
	"update3D"
]

# ***
# ##Internal hook implementation##

# list of all hooks and their registered callbacks
@lists = []

# **check if a plugin provides a named hook method**
hasHook = (plugin, hook) =>
	typeof plugin[hook] is 'function'

# **call the plugin's hook if provided with the passed arguments**
module.exports.call = (plugin, hook, args...) =>
	plugin[hook] args... if hasHook plugin, hook

# ***
# ##Functions for [plugin Loader](pluginLoader.html)##

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
module.exports.init = () =>
	@lists[hook] = [] for hook in @hooks
	for hook in @hooks
		module.exports[hook] =
			do (hook) ->
				(args...) -> callback args... for callback in @lists[hook]

# **register a plugin for all the hooks it provides**
module.exports.register = (plugin) =>
	registerHook plugin, hook for hook in @hooks

# **register a plugin for a specific hook if provided**
registerHook = (plugin, hook) =>
	@lists[hook].push plugin[hook] if hasHook plugin, hook

# **unregister a plugin for all hooks it was registered for**
module.exports.unregister = (plugin) =>
	unregisterHook plugin, hook for hook in @hooks

# **unregister a plugin for a specific hook if provided and registered**
unregisterHook = (plugin, hook) =>
	if hasHook plugin, hook
		index = @lists[hook].indexOf plugin[hook]
		@lists[hook].splice index, 1 if index != -1
