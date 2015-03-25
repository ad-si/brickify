THREE = require 'three'

module.exports.createRenderTarget = (threeRenderer, shaderOptions) ->
	# Create rendertarget
	renderWidth = threeRenderer.domElement.width
	renderHeight = threeRenderer.domElement.height

	depthTexture = new THREE.DepthTexture renderWidth, renderHeight
	renderTargetTexture = new THREE.WebGLRenderTarget(
		renderWidth
		renderHeight
		{
			minFilter: THREE.LinearFilter
			magFilter: THREE.NearestFilter
			format: THREE.RGBAFormat
			depthTexture: depthTexture
		}
	)

	#create scene to render texture
	planeScene = new THREE.Scene()
	screenAlignedQuad = generateQuad(
		renderTargetTexture, depthTexture, shaderOptions
	)
	planeScene.add screenAlignedQuad

	return {
		depthTexture: depthTexture
		renderTarget: renderTargetTexture
		planeScene: planeScene
		blendingMaterial: screenAlignedQuad.material
	}

# Generates an THREE.Mesh that will be displayed as a screen aligned quad
# and will draw the supplied rttTexture while setting the depth value to
# the values specified in rttDepthTexture
generateQuad =  (rttTexture, rttDepthTexture, shaderOptions) ->
	shaderOptions = setDefaultOptions shaderOptions

	mat = new THREE.ShaderMaterial({
		uniforms: {
			tDepth: { type: 't', value: rttDepthTexture }
			tColor: { type: 't', value: rttTexture }
			opacity: { type: 'f', value: shaderOptions.opacity }
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
module.exports.generateQuad = generateQuad

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

		varying vec2 vUv;
		uniform sampler2D tDepth;
		uniform sampler2D tColor;
		uniform float texelXDelta;
		uniform float texelYDelta;
		uniform float opacity;
		uniform vec3 colorMult;

		void main() {
			float currentOpacity = opacity;
			float depth = texture2D( tDepth, vUv ).r;
			if (abs(1.0 - depth) < 0.00001){
				discard;
			}
			vec3 col = texture2D( tColor, vUv ).rgb;

			\n
			' + options.fragmentInMain + '
			\n

			col.r = col.r * colorMult.r;
			col.g = col.g * colorMult.g;
			col.b = col.b * colorMult.b;

			gl_FragColor = vec4( col.r, col.g, col.b, currentOpacity);
			gl_FragDepthEXT = depth;
		}'

setDefaultOptions = (shaderOptions) ->
	shaderOptions = {} if not shaderOptions?

	shaderOptions.opacity ?= 1.0
	shaderOptions.colorMult ?= new THREE.Vector3(1,1,1)
	shaderOptions.fragmentInMain ?= ''

	return shaderOptions
