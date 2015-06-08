THREE = require 'three'
PipelineTargetPart = require './shader/PipelineTargetPart'
ShaderGenerator = require './shader/ShaderGenerator'

###
# @module renderTargetHelper
###

_chooseBiggerSize = false
_overrideSizeValue = null
module.exports.configureSize = (chooseBiggerSize = false, overrideSizeValue = null) ->
	_chooseBiggerSize = chooseBiggerSize
	_overrideSizeValue = overrideSizeValue

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
	threeRenderer
	shaderParts = []
	additionalUniforms = {}
	opacity = 1.0
	textureMagFilter = THREE.LinearFilter
	textureMinFilter = THREE.LinearFilter) ->

	# Create render target
	renderWidth = threeRenderer.domElement.width
	renderHeight = threeRenderer.domElement.height

	texWidth = getNextValidTextureDimension renderWidth
	texHeight = getNextValidTextureDimension renderHeight

	if _overrideSizeValue?
		texWidth = _overrideSizeValue
		texHeight = _overrideSizeValue

	depthTexture = new THREE.DepthTexture texWidth, texHeight, true
	renderTargetTexture = new THREE.WebGLRenderTarget(
		texWidth
		texHeight
		{
			minFilter: textureMinFilter
			magFilter: textureMagFilter
			format: THREE.RGBAFormat
			depthTexture: depthTexture
			stencilBuffer: true
		}
	)

	# apply values to parent, due to broken THREE implementation / WIP pull request
	renderTargetTexture.wrapS = renderTargetTexture.texture.wrapS
	renderTargetTexture.wrapT = renderTargetTexture.texture.wrapT
	renderTargetTexture.magFilter = renderTargetTexture.texture.magFilter
	renderTargetTexture.minFilter = renderTargetTexture.texture.minFilter

	#create scene to render texture
	quadScene = new THREE.Scene()
	screenAlignedQuad = generateQuad(
		renderTargetTexture, depthTexture, shaderParts, additionalUniforms, opacity
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
generateQuad =  (
	rttTexture, rttDepthTexture, shaderParts, additionalUniforms, opacity) ->

	usedShaderParts = []
	usedShaderParts.push new PipelineTargetPart()
	usedShaderParts = usedShaderParts.concat shaderParts

	shaderCode = ShaderGenerator.generateShader usedShaderParts

	baseUniforms = {
		tDepth: { type: 't', value: rttDepthTexture }
		tColor: { type: 't', value: rttTexture }
		opacity: { type: 'f', value: opacity }
		texWidth: { type: 'f', value: rttTexture.width }
		texHeight: { type: 'f', value: rttTexture.height }
	}

	for attribute of additionalUniforms
		baseUniforms[attribute] = additionalUniforms[attribute]

	mat = new THREE.RawShaderMaterial({
		uniforms: baseUniforms
		vertexShader: shaderCode.vertex
		fragmentShader: shaderCode.fragment
		transparent: true
	})

	planeGeometry = new THREE.PlaneBufferGeometry(2,2)
	mesh = new THREE.Mesh( planeGeometry, mat )
	# disable frustum culling since the plane is always visible
	mesh.frustumCulled = false
	return mesh
module.exports.generateQuad = generateQuad

# Chooses the next 2^n size that matches the screen resolution best
getNextValidTextureDimension = (size) ->
	if not size?
		return null

	dims = [64, 128, 256, 512, 1024, 2048, 4096]

	difference = 9999
	selectedDim = 0
	for dim in dims
		d = Math.abs ( dim - size )
		if d < difference
			difference = d
			selectedDim = dim

		if _chooseBiggerSize and dim > size
			return dim

	return selectedDim
module.exports.getNextValidTextureDimension = getNextValidTextureDimension

# Returns true, if the render target has the right
# (in terms of 2^n, see getNextValidTextureDimension)
# size for the domElement of the threeRenderer
renderTargetHasRightSize = (renderTarget, threeRenderer) ->
	screenW = threeRenderer.domElement.clientWidth
	screenH = threeRenderer.domElement.clientHeight

	targetTexWidth = getNextValidTextureDimension screenW, _chooseBiggerSize
	targetTexHeight = getNextValidTextureDimension screenH, _chooseBiggerSize

	if _overrideSizeValue
		targetTexWidth = _overrideSizeValue
		targetTexHeight = _overrideSizeValue

	return (renderTarget.width == targetTexWidth) and
	(renderTarget.height == targetTexHeight)
module.exports.renderTargetHasRightSize = renderTargetHasRightSize
