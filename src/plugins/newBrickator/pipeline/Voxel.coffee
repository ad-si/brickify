class Voxel
	constructor: (@position, dataEntrys = []) ->
		@dataEntrys = dataEntrys
		@brick = false
		@enabled = true
		@definitelyUp = false
		@definitelyDown = false

module.exports = Voxel
