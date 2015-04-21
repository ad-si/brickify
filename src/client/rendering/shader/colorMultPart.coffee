ShaderPart = require './shaderPart'

class ColorMultPart extends ShaderPart
	getVertexVariables: ->
		return ''

	getVertexPreMain: ->
		return ''

	getVertexInMain: ->
		return''

	getFragmentVariables: ->
		return '
			uniform vec3 colorMult;
		'

	getFragmentPreMain: ->
		return ''

	getFragmentInMain: ->
		return '
			col.r = col.r * colorMult.r;
			col.g = col.g * colorMult.g;
			col.b = col.b * colorMult.b;
		'
module.exports = ColorMultPart
