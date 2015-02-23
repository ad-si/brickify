THREE = require 'three'

module.exports = class FancyLineMaterial
	generate: () =>
		options = {
			vertexShader: @_getVertexShader()
			fragmentShader: @_getFragmentShader()
			uniforms: {
				color: { type: "c", value: new THREE.Color( 0xff0000 ) }
			}
			attributes: {}
		}
		mat = new THREE.ShaderMaterial(options)
		return mat

	_getVertexShader: () ->
		return[
			'void main() {'
			'gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);'
			'}'
		].join('\n')

	_getFragmentShader: () ->
		return[
			'void main() {'
			'gl_FragColor = vec4(0,0,0, 1.0);'
			'}'
		].join('\n')
