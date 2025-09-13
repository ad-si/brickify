import THREE from "three"

import PipelineTargetPart from "./shader/PipelineTargetPart.js"
import ShaderGenerator from "./shader/ShaderGenerator.js"


let _chooseBiggerSize = false
let _overrideSizeValue = null


export function configureSize (chooseBiggerSize, overrideSizeValue = null) {
  _chooseBiggerSize = chooseBiggerSize
  return _overrideSizeValue = overrideSizeValue
}


/*
 * Creates a structure that can be used as a render target and later
 * to render the content of the render target
 * with a screen aligned quad to the screen.
 * @return {Object} the render target descriptor
 * @returnprop {THREE.WebGLRenderTarget} renderTarget the render target
 * @returnprop {THREE.DepthTexture} depthTexture depth texture used
 * with the render target
 * @returnprop {THREE.Scene} quadScene a scene which contains the screen
 * aligned quad
 * @returnprop {THREE.ShaderMaterial} blendingMaterial the material used to
 * render the screen aligned quad to the screen
 * @memberOf renderTargetHelper
 */
export function createRenderTarget (
  threeRenderer,
  shaderParts,
  additionalUniforms,
  opacity,
  textureMagFilter,
  textureMinFilter) {

  // Create render target
  if (shaderParts == null) {
    shaderParts = []
  }
  if (additionalUniforms == null) {
    additionalUniforms = {}
  }
  if (opacity == null) {
    opacity = 1.0
  }
  if (textureMagFilter == null) {
    textureMagFilter = THREE.LinearFilter
  }
  if (textureMinFilter == null) {
    textureMinFilter = THREE.LinearFilter
  }
  const renderWidth = threeRenderer.domElement.width
  const renderHeight = threeRenderer.domElement.height

  let texWidth = getNextValidTextureDimension(renderWidth)
  let texHeight = getNextValidTextureDimension(renderHeight)

  if (_overrideSizeValue != null) {
    texWidth = _overrideSizeValue
    texHeight = _overrideSizeValue
  }

  const depthTexture = new THREE.DepthTexture(texWidth, texHeight, true)
  const renderTargetTexture = new THREE.WebGLRenderTarget(
    texWidth,
    texHeight,
    {
      minFilter: textureMinFilter,
      magFilter: textureMagFilter,
      format: THREE.RGBAFormat,
      depthTexture,
      stencilBuffer: true,
    },
  )

  // Apply values to parent, due to broken THREE implementation / WIP pull request
  renderTargetTexture.wrapS = renderTargetTexture.texture.wrapS
  renderTargetTexture.wrapT = renderTargetTexture.texture.wrapT
  renderTargetTexture.magFilter = renderTargetTexture.texture.magFilter
  renderTargetTexture.minFilter = renderTargetTexture.texture.minFilter

  // Create scene to render texture
  const quadScene = new THREE.Scene()
  const screenAlignedQuad = generateQuad(
    renderTargetTexture, depthTexture, shaderParts, additionalUniforms, opacity,
  )
  quadScene.add(screenAlignedQuad)

  return {
    depthTexture,
    renderTarget: renderTargetTexture,
    quadScene,
    blendingMaterial: screenAlignedQuad.material,
  }
}


// Clones the originalTarget but creates a new custom blendingMat shader
export function cloneRenderTarget (
  originalTarget,
  shaderParts, additionalUniforms, opacity,
) {

  // Create scene to render texture
  if (shaderParts == null) {
    shaderParts = []
  }
  if (additionalUniforms == null) {
    additionalUniforms = {}
  }
  if (opacity == null) {
    opacity = 1.0
  }
  const quadScene = new THREE.Scene()
  const screenAlignedQuad = generateQuad(
    originalTarget.renderTarget, originalTarget.depthTexture,
    shaderParts, additionalUniforms, opacity,
  )
  quadScene.add(screenAlignedQuad)

  return {
    depthTexture: originalTarget.depthTexture,
    renderTarget: originalTarget.renderTarget,
    quadScene,
    blendingMaterial: screenAlignedQuad.material,
  }
}


// Generates an THREE.Mesh that will be displayed as a screen aligned quad
// and will draw the supplied rttTexture while setting the depth value to
// the values specified in rttDepthTexture
export function generateQuad (
  rttTexture,
  rttDepthTexture,
  shaderParts,
  additionalUniforms,
  opacity,
) {
  let usedShaderParts = []
  usedShaderParts.push(new PipelineTargetPart())
  usedShaderParts = usedShaderParts.concat(shaderParts)

  const shaderCode = ShaderGenerator.generateShader(usedShaderParts)

  const baseUniforms = {
    tDepth: { type: "t", value: rttDepthTexture },
    tColor: { type: "t", value: rttTexture },
    opacity: { type: "f", value: opacity },
    texWidth: { type: "f", value: rttTexture.width },
    texHeight: { type: "f", value: rttTexture.height },
  }

  for (const attribute in additionalUniforms) {
    baseUniforms[attribute] = additionalUniforms[attribute]
  }

  const mat = new THREE.RawShaderMaterial({
    uniforms: baseUniforms,
    vertexShader: shaderCode.vertex,
    fragmentShader: shaderCode.fragment,
    transparent: true,
  })

  const planeGeometry = new THREE.PlaneBufferGeometry(2, 2)
  const mesh = new THREE.Mesh( planeGeometry, mat )
  // Disable frustum culling since the plane is always visible
  mesh.frustumCulled = false
  return mesh
}


// Chooses the next 2^n size that matches the screen resolution best
export function getNextValidTextureDimension (size) {
  if (size == null) {
    return null
  }

  const dims = [64, 128, 256, 512, 1024, 2048, 4096]

  let difference = 9999
  let selectedDim = 0
  for (const dim of Array.from(dims)) {
    const d = Math.abs( dim - size )
    if (d < difference) {
      difference = d
      selectedDim = dim
    }

    if (_chooseBiggerSize && (dim > size)) {
      return dim
    }
  }

  return selectedDim
}


// Returns true, if the render target has the right
// (in terms of 2^n, see getNextValidTextureDimension)
// size for the domElement of the threeRenderer
export function renderTargetHasRightSize  (renderTarget, threeRenderer) {
  const screenW = threeRenderer.domElement.clientWidth
  const screenH = threeRenderer.domElement.clientHeight

  let targetTexWidth = getNextValidTextureDimension(screenW, _chooseBiggerSize)
  let targetTexHeight = getNextValidTextureDimension(screenH, _chooseBiggerSize)

  if (_overrideSizeValue) {
    targetTexWidth = _overrideSizeValue
    targetTexHeight = _overrideSizeValue
  }

  return (renderTarget.width === targetTexWidth) &&
  (renderTarget.height === targetTexHeight)
}


export function deleteRenderTarget (renderTarget, threeRenderer) {
  renderTarget.renderTarget.dispose()

  if (
    (renderTarget.depthTexture != null
      ? renderTarget.depthTexture.__webglTexture
      : undefined) != null
  ) {
    return threeRenderer.context.deleteTexture(
      renderTarget.depthTexture.__webglTexture,
    )
  }
}
