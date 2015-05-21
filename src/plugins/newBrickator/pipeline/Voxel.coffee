class Voxel
	constructor: (@position, dataEntries = []) ->
		@dataEntries = dataEntries
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

	isLego: =>
		return @enabled

	makeLego: =>
		@enabled = true

	make3dPrinted: =>
		@enabled = false

module.exports = Voxel
