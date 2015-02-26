THREE = require 'three'

module.exports = class LineMatGenerator
	# creates a material that may have a custom z-Buffer offset (z-Delta) to play
	# with depth buffer values.
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
		return mat

	_getVertexShader: () ->
		return[
			'uniform float zDelta;'
			'varying float zVal;'
			'void main() {'
			'vec4 pos = projectionMatrix * modelViewMatrix * vec4(position, 1.0);'
			'gl_Position = vec4(pos.x, pos.y, pos.z + zDelta, pos.w);'
			'zVal = pos.z / pos.w;'
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
