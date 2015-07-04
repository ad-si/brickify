_scadBase = require './brick.scad'

toScadVector = (vector) ->
	return "[#{vector.x}, #{vector.y}, #{vector.z}]"

module.exports.generateScad = (bricks) ->
	files = []
	maxBricksPerScad = 1000
	currentBricks = 0
	numFiles = 0
	scad = ''

	bricks.forEach (brick) =>
		if currentBricks is 0
			scad = _scadDisclaimer()

		pos = toScadVector brick.getPosition()
		size = toScadVector brick.getSize()
		scad += "GridTranslate(#{pos}){ Brick(#{size}); }\n"
		currentBricks++

		if currentBricks == maxBricksPerScad
			scad += '\n\n'
			scad += _scadBase

			files.push {
				fileName: "bricks-#{numFiles}.scad"
				data: scad
			}
			numFiles++
			currentBricks = 0

	scad += '\n\n'
	scad += _scadBase

	files.push {
		fileName: "bricks-#{numFiles}.scad"
		data: scad
	}

	return files

_scadDisclaimer = ->
	return '
		/*\n
		 * \n
		 * Brick layout for openSCAD\n
		 * Generated with http://brickify.it\n
		 *\n
		 */\n\n
	'
