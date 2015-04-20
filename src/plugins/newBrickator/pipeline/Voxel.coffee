class Voxel
	constructor: (@position, dataEntrys = []) ->
		@dataEntrys = dataEntrys
		@brick = false
		@enabled = true
		@definitelyUp = false
		@definitelyDown = false
		@neighbors = {
			Zp: null
			Zm: null
			Xp: null
			Xm: null
			Yp: null
			Ym: null
		}

module.exports = Voxel
