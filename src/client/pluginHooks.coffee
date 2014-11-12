@hooks = [
	"init"
	"updateState"
	"init3D"
	"update3D"
]
@lists = []

module.exports.init = () =>
	@lists[hook] = [] for hook in @hooks
	for hook in @hooks
		module.exports[hook] =
			do (hook) ->
				(args...) -> callback args... for callback in @lists[hook]

hasHook = (plugin, hook) =>
	typeof plugin[hook] is 'function'

module.exports.register = (plugin) =>
	registerHook plugin, hook for hook in @hooks

registerHook = (plugin, hook) =>
	@lists[hook].push plugin[hook] if hasHook plugin, hook

module.exports.unregister = (plugin) =>
	unregisterHook plugin, hook for hook in @hooks

unregisterHook = (plugin, hook) =>
	if hasHook plugin, hook
		index = @lists[hook].indexOf plugin[hook]
		@lists[hook].splice index, 1 if index != -1

module.exports.call = (plugin, hook, args...) =>
	plugin[hook] args... if hasHook plugin, hook
