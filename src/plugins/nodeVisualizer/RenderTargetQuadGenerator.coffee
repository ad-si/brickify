THREE = require 'three'

# Generates an THREE.Mesh that will be displayed as a screen aligned quad
# and will draw the supplied rttTexture while setting the depth value to
# the values specified in rttDepthTexture
module.exports.generateQuad =  (rttTexture, rttDepthTexture, shaderOptions) ->
	shaderOptions = setDefaultOptions shaderOptions

	mat = new THREE.ShaderMaterial({
		uniforms: {
			tDepth: { type: 't', value: rttDepthTexture }
			tColor: { type: 't', value: rttTexture }
			colorMult: { type: 'v3', value: shaderOptions.colorMult }
			texelXDelta: { type: 'f', value: 1.0 / rttTexture.width }
			texelYDelta: { type: 'f', value: 1.0 / rttTexture.height }
		}
		vertexShader: vertexShader()
		fragmentShader: fragmentShader(shaderOptions)
		transparent: true
	})

	planeGeometry = new THREE.PlaneBufferGeometry(2,2)
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
		uniform float texelXDelta;
		uniform float texelYDelta;
		uniform vec3 colorMult;

		void main() {
			float depth = texture2D( tDepth, vUv ).r;
			if (abs(1.0 - depth) < 0.00001){
				discard;
			}

			vec3 col = texture2D( tColor, vUv ).rgb;

			const int kernel = 2;
			bool isLine = false;
 			
			for (int x = -1 * (kernel - 1); x < kernel; x++){
				for (int y = -1 * (kernel - 1); y < kernel; y++){
					float tx = vUv.s + float(x) * texelXDelta;
					float ty = vUv.t + float(y) * texelYDelta;
					
					vec3 c = texture2D( tColor, vec2(tx,ty)).rgb;

					if (c.r < 0.1 && c.g < 0.1 && c.b < 0.1){
						isLine = true;
					}
				}
			}
			if (isLine){
				col.r = 0.0;
				col.g = 0.0;
				col.b = 0.0;
			}

			col.r = col.r * colorMult.r;
			col.g = col.g * colorMult.g;
			col.b = col.b * colorMult.b;

			gl_FragColor = vec4( col.r, col.g, col.b, OPACITY);
			gl_FragDepthEXT = depth;
		}'

setDefaultOptions = (shaderOptions) ->
	shaderOptions = {} if not shaderOptions?

	if not shaderOptions.opacity?
		shaderOptions.opacity = '1.00'
	else
		shaderOptions.opacity = parseFloat(shaderOptions.opacity).toFixed(2)

	if not shaderOptions.colorMult?
		shaderOptions.colorMult = new THREE.Vector3(1,1,1)

	return shaderOptions
