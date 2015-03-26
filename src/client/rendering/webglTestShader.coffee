module.exports.fragmentPrimary = '
	precision highp float;

	void main(void){
		gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
	}

'

module.exports.vertexPrimary = '
	precision highp float;
	attribute vec3 position;

	varying vec2 texCoords;

	void main(void){
		float tx = position.x * 0.5 + 1.0;
		float ty = position.y * 0.5 + 1.0;
		texCoords = vec2(tx, ty);

		gl_Position = vec4(position, 1.0);
	}
'

module.exports.fragmentSecondary = '
	precision highp float;

	uniform sampler2D colorTexture;
	uniform sampler2D depthTexture;

	varying vec2 texCoords;

	void main(void){
		vec4 col = texture2D(colorTexture, texCoords);
		float depth = texture2D(depthTexture, texCoords).r;

		gl_FragColor = col;
	}
'