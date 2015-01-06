# Helper Class that - after voxelising and layouting -
# contains the voxelised grid, it's ThreeJS representation
# and the ThreeJs
module.exports = class FabrickatorModelData
	constructor: (@node, @grid, @gridForThree,
								@layout = null, @layoutForThree = null) ->
		return
	addLayout: (@layout, @layoutForThree) => return
