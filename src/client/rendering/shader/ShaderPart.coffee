###
# base class to describe a part (in terms of special functionality) of a shader
###
class ShaderPart
	constructor: (options) -> return

	getVertexVariables: ->
		return ''

	getVertexPreMain: ->
		return ''

	getVertexInMain: ->
		return ''

	getFragmentVariables: ->
		return ''

	getFragmentPreMain: ->
		return ''

	getFragmentInMain: ->
		return ''

module.exports = ShaderPart
