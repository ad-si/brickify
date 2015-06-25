# Mainly inspired from http://theorangeduck.com/page/pure-depth-ssao

ShaderPart = require './shaderPart'

class SsaoBlurPart extends ShaderPart
	getFragmentPreMain: ->
		return '
			float ssaoBlur(vec2 texCoords){
				float gaussKernelValues[81];
				gaussKernelValues[0] = 0.00839;
				gaussKernelValues[1] = 0.00965;
				gaussKernelValues[2] = 0.01066;
				gaussKernelValues[3] = 0.01132;
				gaussKernelValues[4] = 0.01155;
				gaussKernelValues[5] = 0.01132;
				gaussKernelValues[6] = 0.01066;
				gaussKernelValues[7] = 0.00965;
				gaussKernelValues[8] = 0.00839;
				gaussKernelValues[9] = 0.00965;
				gaussKernelValues[10] = 0.01110;
				gaussKernelValues[11] = 0.01226;
				gaussKernelValues[12] = 0.01302;
				gaussKernelValues[13] = 0.01328;
				gaussKernelValues[14] = 0.01302;
				gaussKernelValues[15] = 0.01226;
				gaussKernelValues[16] = 0.01110;
				gaussKernelValues[17] = 0.00965;
				gaussKernelValues[18] = 0.01066;
				gaussKernelValues[19] = 0.01226;
				gaussKernelValues[20] = 0.01355;
				gaussKernelValues[21] = 0.01439;
				gaussKernelValues[22] = 0.01468;
				gaussKernelValues[23] = 0.01439;
				gaussKernelValues[24] = 0.01355;
				gaussKernelValues[25] = 0.01226;
				gaussKernelValues[26] = 0.01066;
				gaussKernelValues[27] = 0.01132;
				gaussKernelValues[28] = 0.01302;
				gaussKernelValues[29] = 0.01439;
				gaussKernelValues[30] = 0.01528;
				gaussKernelValues[31] = 0.01559;
				gaussKernelValues[32] = 0.01528;
				gaussKernelValues[33] = 0.01439;
				gaussKernelValues[34] = 0.01302;
				gaussKernelValues[35] = 0.01132;
				gaussKernelValues[36] = 0.01155;
				gaussKernelValues[37] = 0.01328;
				gaussKernelValues[38] = 0.01468;
				gaussKernelValues[39] = 0.01559;
				gaussKernelValues[40] = 0.01590;
				gaussKernelValues[41] = 0.01559;
				gaussKernelValues[42] = 0.01468;
				gaussKernelValues[43] = 0.01328;
				gaussKernelValues[44] = 0.01155;
				gaussKernelValues[45] = 0.01132;
				gaussKernelValues[46] = 0.01302;
				gaussKernelValues[47] = 0.01439;
				gaussKernelValues[48] = 0.01528;
				gaussKernelValues[49] = 0.01559;
				gaussKernelValues[50] = 0.01528;
				gaussKernelValues[51] = 0.01439;
				gaussKernelValues[52] = 0.01302;
				gaussKernelValues[53] = 0.01132;
				gaussKernelValues[54] = 0.01066;
				gaussKernelValues[55] = 0.01226;
				gaussKernelValues[56] = 0.01355;
				gaussKernelValues[57] = 0.01439;
				gaussKernelValues[58] = 0.01468;
				gaussKernelValues[59] = 0.01439;
				gaussKernelValues[60] = 0.01355;
				gaussKernelValues[61] = 0.01226;
				gaussKernelValues[62] = 0.01066;
				gaussKernelValues[63] = 0.00965;
				gaussKernelValues[64] = 0.01110;
				gaussKernelValues[65] = 0.01226;
				gaussKernelValues[66] = 0.01302;
				gaussKernelValues[67] = 0.01328;
				gaussKernelValues[68] = 0.01302;
				gaussKernelValues[69] = 0.01226;
				gaussKernelValues[70] = 0.01110;
				gaussKernelValues[71] = 0.00965;
				gaussKernelValues[72] = 0.00839;
				gaussKernelValues[73] = 0.00965;
				gaussKernelValues[74] = 0.01066;
				gaussKernelValues[75] = 0.01132;
				gaussKernelValues[76] = 0.01155;
				gaussKernelValues[77] = 0.01132;
				gaussKernelValues[78] = 0.01066;
				gaussKernelValues[79] = 0.00965;
				gaussKernelValues[80] = 0.00839;

				float dX = 1.0 / texWidth;
				float dY = 1.0 / texHeight;
				const int kernelSize = 4;
				float value = 0.0;

				for (int kernelIndex = 0; kernelIndex < 81; kernelIndex++){
					float x = mod(float(kernelIndex), float(kernelSize*2+1))
					- float(kernelSize);
					float y = floor(float(kernelIndex)/float(kernelSize*2+1))
					- float(kernelSize);

					float tx = texCoords.x + x * dX;
					float ty = texCoords.y + y * dY;

					float weight = gaussKernelValues[kernelIndex];
					float currentValue = texture2D(tColor, vec2(tx, ty)).r;
					value = value + currentValue * weight;
				}

				return value;
			}
		'

	getFragmentInMain: ->
		return '
			float blur = ssaoBlur(vUv);
			/* Current color is black as it is initialized as such */
			currentOpacity = 1.0 - blur;
		'

module.exports = SsaoBlurPart
