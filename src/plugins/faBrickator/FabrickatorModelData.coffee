# Helper Class that - after voxelising and layouting -
# contains the voxelised grid, its ThreeJS representation
# and the ThreeJs
module.exports = class FabrickatorModelData
	constructor: (@node, @grid, @gridForThree,
								@layout = null, @layoutForThree = null) ->
		return
	setLayout: (@layout, @layoutForThree) => return
