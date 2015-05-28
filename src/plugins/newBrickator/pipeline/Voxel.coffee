class Voxel

	constructor: (@position, @direction) ->
		# direction means 1: up, 0 undecided, -1 down

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

	setDirection: (direction) ->
		if @direction
			@direction = 0 unless @direction is direction
		else
			@direction = direction

module.exports = Voxel
