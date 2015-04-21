###
# Takes several shader parts and creates a shader material out of it
###
class ShaderGenerator
	@generateShader: (arrayOfParts) ->
		vertexVariables = ''
		vertexPreMain = ''
		vertexInMain = ''
		fragmentVariables = ''
		fragmentPreMain = ''
		fragmentInMain = ''

		for part in arrayOfParts
			vertexVariables += '\n'
			vertexVariables += part.getVertexVariables()
			vertexVariables += '\n'

			vertexPreMain += '\n'
			vertexPreMain += part.getVertexPreMain()
			vertexPreMain += '\n'

			vertexInMain += '\n'
			vertexInMain += part.getVertexInMain()
			vertexInMain += '\n'

			fragmentVariables += '\n'
			fragmentVariables += part.getFragmentVariables()
			fragmentVariables += '\n'

			fragmentPreMain += '\n'
			fragmentPreMain += part.getFragmentPreMain()
			fragmentPreMain += '\n'

			fragmentInMain += '\n'
			fragmentInMain += part.getFragmentInMain()
			fragmentInMain += '\n'

		vert = ShaderGenerator._generateVertexShader(
			vertexVariables, vertexPreMain, vertexInMain
		)

		frag = ShaderGenerator._generateFragmentShader(
			fragmentVariables, fragmentPreMain, fragmentInMain
		)

		return {
			vertex: vert
			fragment: frag
		}

	@_generateVertexShader: (variables, preMain, inMain) ->
		shaderCode = '
			precision highp float;
			precision highp int;

			uniform float texWidth;
			uniform float texHeight;

			attribute vec3 position;
			attribute vec2 uv;

			varying vec2 vUv;
		'
		shaderCode += variables
		shaderCode += preMain
		shaderCode += '
			void main() {
				vUv = uv;
				vec4 pos = vec4(position.xyz, 1.0);

				' + inMain + '

				gl_Position = pos;
			}
		'
		return shaderCode

	@_generateFragmentShader: (variables, preMain, inMain) ->
		shaderCode = '
			#extension GL_EXT_frag_depth : enable\n
			precision highp float;
			precision highp int;

			uniform float texWidth;
			uniform float texHeight;

			varying vec2 vUv;
			uniform float opacity;
		'
		shaderCode += variables
		shaderCode += preMain
		shaderCode += '
			void main(){
				vec4 col = vec4(0.0, 0.0, 0.0, 0.0);\n
				float currentOpacity = opacity;
				\n
				' + inMain + '
				\n
				col.a = currentOpacity;
				gl_FragColor = col;
			}
		'
		return shaderCode
module.exports = ShaderGenerator
