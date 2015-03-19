THREE = require 'three'

module.exports.generateMaterial =  (rttTexture, rttDepthTexture) ->
	mat = new THREE.ShaderMaterial({
		uniforms: {
			tDepth: { type: 't', value: rttDepthTexture }
			tColor: { type: 't', value: rttTexture }
		}
		vertexShader: vertexShader()
		fragmentShader: fragmentShader()
	})

	return mat

vertexShader = ->
	return '
		varying vec2 vUv;
		void main() {
			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
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
			/*depth = smoothstep(0.99, 1.00, depth);*/

			gl_FragColor = vec4(depth, depth, depth, 1.0);
			gl_FragColor = texture2D( tColor, vUv);
			gl_FragDepthEXT = depth;
		}'
