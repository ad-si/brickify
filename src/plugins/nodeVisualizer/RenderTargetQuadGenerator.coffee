THREE = require 'three'

planeGeometry = new THREE.PlaneBufferGeometry(2,2)

# Generates an THREE.Mesh that will be displayed as a screen aligned quad
# and will draw the supplied rttTexture while setting the depth value to
# the values specified in rttDepthTexture
module.exports.generateQuad =  (rttTexture, rttDepthTexture) ->
	mat = new THREE.ShaderMaterial({
		uniforms: {
			tDepth: { type: 't', value: rttDepthTexture }
			tColor: { type: 't', value: rttTexture }
		}
		vertexShader: vertexShader()
		fragmentShader: fragmentShader()
	})

	return new THREE.Mesh( planeGeometry, mat )

vertexShader = ->
	return '
		varying vec2 vUv;
		void main() {
			vUv = uv;
			/* Dont transform coordinates, make this a screen aligned quad */
			gl_Position = vec4( position, 1.0 );
		}
	'
fragmentShader = ->
	return '
		#extension GL_EXT_frag_depth : enable\n

		varying vec2 vUv;
		uniform sampler2D tDepth;
		uniform sampler2D tColor;

		void main() {
			float depth = texture2D( tDepth, vUv).r;
			gl_FragColor = texture2D( tColor, vUv);
			gl_FragDepthEXT = depth;
		}'
