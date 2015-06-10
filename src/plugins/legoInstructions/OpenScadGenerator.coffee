_scadBase = require './brick.scad'

toScadVector = (vector) ->
	return "[#{vector.x}, #{vector.y}, #{vector.z}]"

module.exports.generateScad = (bricks) ->
	scad = _scadDisclaimer()

	bricks.forEach (brick) ->
		pos = toScadVector brick.getPosition()
		size = toScadVector brick.getSize()
		scad += "GridTranslate(#{pos}){ Brick(#{size}); }\n"

	scad += '\n\n'
	scad += _scadBase

	return {
		fileName: 'bricks.scad'
		data: scad
	}

_scadDisclaimer = ->
	return '
		/*\n
		 * \n
		 * Brick layout for openSCAD\n
		 * Generated with http://brickify.it\n
		 *\n
		 */\n\n
	'
