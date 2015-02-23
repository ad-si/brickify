THREE = require 'three'

module.exports = class LineMatGenerator
	generate: (color = 0x000000, zDelta = 0.0) =>
		options = {
			vertexShader: @_getVertexShader()
			fragmentShader: @_getFragmentShader()
			uniforms: {
				linecolor: { type: 'c', value: new THREE.Color( color ) }
				zDelta: { type: 'f', value: zDelta}
			}
			attributes: {}
		}
		mat = new THREE.ShaderMaterial(options)
		mat.linewidth = 3
		return mat

	_getVertexShader: () ->
		return[
			'uniform float zDelta;'
			'varying float zVal;'
			'void main() {'
			'vec4 pos = projectionMatrix * modelViewMatrix * vec4(position, 1.0);'
			'pos.z = pos.z - zDelta;'
			'gl_Position = pos;'
			'zVal = (pos.z + zDelta) / pos.w;'
			'}'
		].join('\n')

	_getFragmentShader: () ->
		return[
			'varying float zVal;'
			'uniform vec3 linecolor;'
			'void main() {'
			'vec3 fog = vec3(1,1,1);'
			'vec3 color = linecolor ;//+ fog * smoothstep(0.995, 1.005, zVal);'
			'gl_FragColor = vec4(color.r, color.g, color.b, 1.0);'
			'}'
		].join('\n')
