module.exports.fragmentPrimary = '
	precision highp float;

	void main(void){
		gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
	}

'

module.exports.vertexPrimary = '
	precision highp float;
	attribute vec3 position;

	void main(void){
		gl_Position = vec4(position, 1.0);
	}
'
