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
		float tx = position.x * 5.0;
		float ty = position.y * 5.0;
		texCoords = vec2(tx, ty);

		gl_Position = vec4(position, 1.0);
	}
'

module.exports.fragmentSecondary = '
	#extension GL_EXT_frag_depth : enable\n

	precision highp float;

	uniform sampler2D colorTexture;
	uniform sampler2D depthTexture;

	varying vec2 texCoords;

	void main(void){
		vec2 cr = vec2(texCoords.x + 0.1, texCoords.y + 0.1);
		vec2 cg = vec2(texCoords.x + 0.15, texCoords.y + 0.15);
		vec2 cb = vec2(texCoords.x + 0.2, texCoords.y + 0.2);

		vec4 col = vec4(0,0,0,1);
		col.r = texture2D(colorTexture, cr).r;
		col.g = texture2D(colorTexture, cg).g;
		col.b = texture2D(colorTexture, cb).b;

		float depth = texture2D(depthTexture, texCoords).r;

		gl_FragColor = col;
		gl_FragDepthEXT = depth;
	}
'
