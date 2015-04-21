ShaderPart = require './ShaderPart'

class PipelineTargetPart extends ShaderPart
	getVertexVariables: ->
		return ''

	getVertexPreMain: ->
		return ''

	getVertexInMain: ->
		# make this a screen aligned quad with z=0.5
		return '
			pos.x = pos.x;
			pos.y = pos.y;
			pos.z = 0.5;
			pos.w = 1.0;
		'

	getFragmentVariables: ->
		return '
			uniform sampler2D tDepth;
			uniform sampler2D tColor;
		'

	getFragmentPreMain: ->
		return ''

	getFragmentInMain: ->
		return '
			col = texture2D( tColor, vUv );
			col.a = 1.0;

			float depth = texture2D( tDepth, vUv ).r;
			if (abs(1.0 - depth) < 0.00001){
				discard;
			}
			gl_FragDepthEXT = depth;
		'

module.exports = PipelineTargetPart
