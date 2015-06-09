_scadBase = require './brick.scad'

module.exports.generateScad = (bricks) ->
	scad = _scadDisclaimer()

	bricks.forEach (brick) ->
		pos = "[#{brick.getPosition().x},
		#{brick.getPosition().y},#{brick.getPosition().z}]"
		size = "[#{brick.getSize().x},#{brick.getSize().y},#{brick.getSize().z}]"
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
