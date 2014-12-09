###
# @module pluginLoader
###

# Load the hook list and initialize the pluginHook management
path = require 'path'
THREE = require 'three'
$ = require 'jquery'
hooks = require './pluginHooks.yaml'
PluginHooks = require '../common/pluginHooks'

module.exports = class PluginLoader
	constructor: (globalConfigInstance) ->
		@pluginHooks = new PluginHooks()
		@pluginHooks.initHooks(hooks)
		@globalConfig = globalConfigInstance

	initPlugin: (PluginClass, packageData) ->
		instance = new PluginClass()

		for own key,value of packageData
			instance[key] = value

		instance.init? @globalConfig

		if @renderer?
			instance.init3d? threeNode = new THREE.Object3D()

		instance.initUi? {
			menuBar: document.getElementById 'navbarToggle'
			toolsContainer: document.getElementById 'toolsContainer'
			sceneGraphContainer: document.getElementById 'sceneGraphContainer'
		}

		schema = instance.getUiSchema?()

		if schema?
			$pluginsContainer = $('#pluginsContainer')
			$pluginContainer = $("<div id='#{instance.name}'></div>")

			$pluginsContainer.append($pluginContainer)

			editor = new JSONEditor($pluginContainer[0], {
				theme: 'bootstrap3',
				schema: schema,
				disable_array_add: true,
				disable_array_delete: true,
				disable_array_reorder: true,
				disable_collapse: true,
				disable_edit_json: true,
				disable_properties: true
			})

		@pluginHooks.register instance

		if @renderer? and threeNode?
			@renderer.addToScene threeNode

		return instance

	# Since browserify.js does not support dynamic require
	# all plugins must be explicitly written down
	loadPlugins: (@renderer) ->
		pluginInstances = []

		pluginInstances.push @initPlugin(
			require('./plugins/dummy'),
			require('./plugins/dummy/package.json')
		)
		pluginInstances.push @initPlugin(
			require('./plugins/example'),
			require('./plugins/example/package.json')
		)
		pluginInstances.push @initPlugin(
			require('./plugins/coordinateSystem'),
			require('./plugins/coordinateSystem/package.json')
		)
		pluginInstances.push @initPlugin(
			require('./plugins/solidRenderer'),
			require('./plugins/solidRenderer/package.json')
		)
		pluginInstances.push @initPlugin(
			require('./plugins/stlImport'),
			require('./plugins/stlImport/package.json')
		)
		pluginInstances.push @initPlugin(
			require('./plugins/stlExport'),
			require('./plugins/stlExport/package.json')
		)
		pluginInstances.push @initPlugin(
			require('./plugins/sceneGraph'),
			require('./plugins/sceneGraph/package.json')
		)

		return pluginInstances
