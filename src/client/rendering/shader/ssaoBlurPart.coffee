# Mainly inspired from http://theorangeduck.com/page/pure-depth-ssao

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
				float dX = 1.0 / texWidth;
				float dY = 1.0 / texHeight;
				const int kernelSize = 3;
				float value = texture2D(tColor, texCoords).r;

				for (int x = -kernelSize; x <= kernelSize; x++){
					for (int y = -kernelSize; y <= kernelSize; y++){
						if (x != 0 && y != 0){
							float fx = float(x);
							float fy = float(y);

							float tx = texCoords.x + fx * dX;
							float ty = texCoords.y + fy * dY;

							float weight = 1.0 / ((abs(fx) + 0.5) * (abs(fy) + 0.5));
							float currentValue = texture2D(tColor, vec2(tx, ty)).r;
							value = value * (1.0 - weight) + currentValue * (weight);
						}
					}
				}

				return value;
			}
		'

	getFragmentInMain: ->
		return '
			float blur = ssaoBlur(vUv);
			col = vec4(0.0);
			currentOpacity = 1.0 - blur;
		'

module.exports = SsaoBlurPart
