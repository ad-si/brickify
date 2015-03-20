THREE = require 'three'

planeGeometry = new THREE.PlaneBufferGeometry(2,2)

# Generates an THREE.Mesh that will be displayed as a screen aligned quad
# and will draw the supplied rttTexture while setting the depth value to
# the values specified in rttDepthTexture
module.exports.generateQuad =  (rttTexture, rttDepthTexture, shaderOptions = {}) ->
	if not shaderOptions.opacity?
		shaderOptions.opacity = '1.00'
	else
		shaderOptions.opacity = parseFloat(shaderOptions.opacity).toFixed(2)

	mat = new THREE.ShaderMaterial({
		uniforms: {
			tDepth: { type: 't', value: rttDepthTexture }
			tColor: { type: 't', value: rttTexture }
		}
		vertexShader: vertexShader()
		fragmentShader: fragmentShader(shaderOptions)
		transparent: true
	})

	console.log mat.fragmentShader

	return new THREE.Mesh( planeGeometry, mat )

vertexShader = (options) ->
	return '
		varying vec2 vUv;
		void main() {
			vUv = uv;
			/* Dont transform coordinates, make this a screen aligned quad */
			gl_Position = vec4( position, 1.0 );
		}
	'
fragmentShader = (options) ->
	return '
		#extension GL_EXT_frag_depth : enable\n

		#define OPACITY ' + options.opacity + '\n
		
		varying vec2 vUv;
		uniform sampler2D tDepth;
		uniform sampler2D tColor;

		void main() {
			float depth = texture2D( tDepth, vUv).r;

			vec3 col = texture2D( tColor, vUv ).rgb;
			gl_FragColor = vec4( col.r, col.g, col.b, OPACITY);
			gl_FragDepthEXT = depth;
		}'
