jsondiffpatch = require 'jsondiffpatch'

module.exports.createJsonDiffPatch = () ->
	diffpatch = jsondiffpatch.create objectHash: arrayObjectIdentifier
	return diffpatch

# compare objects in arrays by threeId or by using json.stringify
# hash in this context means = object id
# --> if the hash is the same, these objects are the same, but may have changed
# --> equal hash != equal content
arrayObjectIdentifier = (obj) ->
	# return three id for sceneNodes for smaller
	if obj.pluginData?.solidRenderer?.threeObjectUuid?
		return obj.pluginData.solidRenderer.threeObjectUuid

	return JSON.stringify(obj)
