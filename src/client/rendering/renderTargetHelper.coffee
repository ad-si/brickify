THREE = require 'three'
###
# @module renderTargetHelper
###

###
# Creates a structure that can be used as a render target and later
# to render the content of the render target
# with a screen aligned quad to the screen.
# @return {Object} the render target descriptor
# @returnprop {THREE.WebGLRenderTarget} renderTarget the render target
# @returnprop {THREE.DepthTexture} depthTexture depth texture used
# with the render target
# @returnprop {THREE.Scene} quadScene a scene which contains the screen
# aligned quad
# @returnprop {THREE.ShaderMaterial} blendingMaterial the material used to
# render the screen aligned quad to the screen
# @memberOf renderTargetHelper
###
module.exports.createRenderTarget = (
	threeRenderer, shaderOptions, textureFilter = THREE.LinearFilter) ->

	# Create rendertarget
	renderWidth = threeRenderer.domElement.width
	renderHeight = threeRenderer.domElement.height

	texWidth = getNextValidTextureDimension renderWidth
	texHeight = getNextValidTextureDimension renderHeight

	depthTexture = new THREE.DepthTexture texWidth, texHeight
	renderTargetTexture = new THREE.WebGLRenderTarget(
		texWidth
		texHeight
		{
			minFilter: textureFilter
			magFilter: textureFilter
			format: THREE.RGBAFormat
			depthTexture: depthTexture
			stencilBuffer: false
		}
	)

	# apply values to parent, due to broken THREE implementation / WIP pullrequest
	renderTargetTexture.wrapS = renderTargetTexture.texture.wrapS
	renderTargetTexture.wrapT = renderTargetTexture.texture.wrapT
	renderTargetTexture.magFilter = renderTargetTexture.texture.magFilter
	renderTargetTexture.minFilter = renderTargetTexture.texture.minFilter

	#create scene to render texture
	quadScene = new THREE.Scene()
	screenAlignedQuad = generateQuad(
		renderTargetTexture, depthTexture, shaderOptions
	)
	quadScene.add screenAlignedQuad

	return {
		depthTexture: depthTexture
		renderTarget: renderTargetTexture
		quadScene: quadScene
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

# Choses the next 2^n size that matches the screen resolution best
getNextValidTextureDimension = (size) ->
	dims = [64, 128, 256, 512, 1024, 2048, 4096]

	difference = 9999
	selectedDim = 0
	for dim in dims
		d = Math.abs ( dim - size )
		if d < difference
			difference = d
			selectedDim = dim

	return selectedDim
module.exports.getNextValidTextureDimension = getNextValidTextureDimension

# Returns true, if the render target has the right
# (in terms of 2^n, see getNextValidTextureDimension)
# size for the domElement of the threeRenderer
renderTargetHasRightSize = (renderTarget, threeRenderer) ->
	screenW = threeRenderer.domElement.clientWidth
	screenH = threeRenderer.domElement.clientHeight

	targetTexWidth = getNextValidTextureDimension screenW
	targetTexHeight = getNextValidTextureDimension screenH

	return (renderTarget.width == targetTexWidth) and
	(renderTarget.height == targetTexHeight)
module.exports.renderTargetHasRightSize = renderTargetHasRightSize
