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

			attribute vec3 position;
			attribute vec2 uv;

			varying vec2 vUv;
		'
		shaderCode += variables
		shaderCode += preMain
		shaderCode += '
			void main() {
				vUv = uv;
				vec4 pos = position;

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
			varying vec2 vUv;
		'
		shaderCode += variables
		shaderCode += preMain
		shaderCode += '
			void main(){
				vec4 col = vec4(0.0, 0.0, 0.0, 0.0);\n
				\n
				+ ' + inMain + ' +
				\n
				gl_FragColor = col;
			}
		'
		return shaderCode


