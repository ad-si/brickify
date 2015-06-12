class Voxel

	constructor: (@position) ->

		@brick = false
		@enabled = true
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
