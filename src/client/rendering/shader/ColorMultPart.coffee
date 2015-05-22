ShaderPart = require './ShaderPart'

class ColorMultPart extends ShaderPart
	getFragmentVariables: ->
		return '
			uniform vec3 colorMult;
		'

	getFragmentInMain: ->
		return '
			col.r = col.r * colorMult.r;
			col.g = col.g * colorMult.g;
			col.b = col.b * colorMult.b;
		'

module.exports = ColorMultPart
