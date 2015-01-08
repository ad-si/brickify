globalConfig = require '../client/globals.yaml'
objectTree = require '../common/objectTree'
Bundle = require '../client/bundle'

# Set renderer size to fit to 3 bootstrap columns
globalConfig.staticRendererSize = true
globalConfig.staticRendererWidth = 388
globalConfig.staticRendererHeight = 388
globalConfig.syncWithServer = false

#clone global config 3 times
configString = JSON.stringify(globalConfig)
config1 = JSON.parse configString
config2 = JSON.parse configString
config3 = JSON.parse configString

# instantiate 3 lowfab bundles
config1.renderAreaId = 'renderArea1'
bundle1 = new Bundle config1
b1 = bundle1.init()

config2.renderAreaId = 'renderArea2'
bundle2 = new Bundle config2
b2 = bundle2.init()

config3.renderAreaId = 'renderArea3'
bundle3 = new Bundle config3
b3 = bundle3.init()

#get model from url
hash = window.location.hash

if hash.indexOf('+error') >= 0
	$('#importerrors').show()
	#remove error note from hash
	hash = hash.substring 0, hash.length - 7

#remove '#'
hash = hash.substring 1,hash.length

#adjust links to editor according to model hash
applinks = $('.applink')
for link in applinks
	vanillaLink = link.href
	vanillaLink += 'initialModel=' + hash
	link.href = vanillaLink

#load model into all bundles
b1.then(() -> bundle1.modelLoader.loadByHash hash)
b2.then(() -> bundle2.modelLoader.loadByHash hash)
b3.then(() -> bundle3.modelLoader.loadByHash hash)
