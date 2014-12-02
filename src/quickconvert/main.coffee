globalConfig = require '../client/globals.yaml'
_renderer = require '../client/renderer'
pluginLoader = require '../client/pluginLoader'
statesync = require '../client/statesync'
objectTree = require '../common/objectTree'
coordinateSystem = require '../client/plugins/coordinateSystem/coordinateSystem'

globalConfig.staticRendererSize = true
globalConfig.staticRendererWidth = 388
globalConfig.staticRendererHeight = 388

renderer = _renderer.defaultInstance
renderer.init globalConfig

coordinateSystem.init globalConfig

globalConfig.renderAreaId = 'renderArea2'
renderer2 = new _renderer.Renderer()
renderer2.init globalConfig
obj = new THREE.Object3D()
renderer2.addToScene obj
coordinateSystem.init3d obj

globalConfig.renderAreaId = 'renderArea3'
renderer3 = new _renderer.Renderer()
renderer3.init globalConfig
obj2 = new THREE.Object3D()
renderer3.addToScene obj2
coordinateSystem.init3d obj2

#get model from url
hash = window.location.hash

if hash.indexOf('+error') < 0
	$('#importerrors').hide()
else
	#remove error note from hash
	hash = hash.substring 0, hash.length - 7

#remove '#'
hash = hash.substring 1,hash.length

#adjust links to editor according to model hash
vanillaLink = $('.applink').attr('href')
vanillaLink += 'initialModel=' + hash
$('.applink').attr('href', vanillaLink)

statesync.init globalConfig, (state) ->
	objectTree.init state
	pluginLoader.init globalConfig
	pluginLoader.loadPlugins()
