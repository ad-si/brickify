modelCache = require '../../client/modelCache'
interactionHelper = require '../../client/interactionHelper'
THREE = require 'three'
objectTree = require '../../common/state/objectTree'

module.exports = class ThreeDPrint
	constructor: () -> return

	init: (@bundle) => return
	init3d: (@threejsRootNode) => return

	getConvertUiSchema: () =>
		return ''
