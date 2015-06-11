# mainly inspired from http://theorangeduck.com/page/pure-depth-ssao

ShaderPart = require './shaderPart'

class SsaoBlurPart extends ShaderPart
	getVertexVariables: ->
		return ''

	getVertexPreMain: ->
		return ''

	getVertexInMain: ->
		return''

	getFragmentVariables: ->
		return ''

	getFragmentPreMain: ->
		return '
			float ssaoBlur(vec2 texCoords){
				float dX = 1.0 / texWidth;\n
				float dY = 1.0 / texHeight;\n
				const int kernelSize = 3;\n

				float value = texture2D(tColor, texCoords).r;\n

				for (int x = -kernelSize; x <= kernelSize; x++){\n
					for (int y = -kernelSize; y <= kernelSize; y++){\n
						if (x != 0 && y != 0){\n
							float fx = float(x);\n
							float fy = float(y);\n

							float tx = texCoords.x + fx * dX;\n
							float ty = texCoords.y + fy * dY;\n

							float weight = 1.0 / ((abs(fx) + 0.5) * (abs(fy) + 0.5));\n
							float currentValue = texture2D(tColor, vec2(tx, ty)).r;\n
							value = value * (1.0 - weight) + currentValue * (weight);\n
						}\n
					}\n
				}\n

				return value;\n
			}
		'

	getFragmentInMain: ->
		return '
			float blur = ssaoBlur(vUv);
			col = vec4(0.0);
			currentOpacity = 1.0 - blur;

			/*col = texture2D(tColor, vUv);
			col.a = 1.0;
			currentOpacity = 1.0;*/
		'

module.exports = SsaoBlurPart
