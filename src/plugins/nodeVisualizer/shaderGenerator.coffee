module.exports.buildFragmentMainAdditions = (options) ->
	result = ''

	if options.expandBlack
		result += '\n' + fragExpandBlack() + '\n'

	if options.blackAlwaysOpaque
		result += '\n' + fragBlackAlwaysOpaque() + '\n'

	return result

fragExpandBlack = ->
	return'
		const int kernel = 2;
		bool isLine = false;
			
		for (int x = -1 * (kernel - 1); x < kernel; x++){
			for (int y = -1 * (kernel - 1); y < kernel; y++){
				float tx = vUv.s + float(x) * texelXDelta;
				float ty = vUv.t + float(y) * texelYDelta;
				
				vec3 c = texture2D( tColor, vec2(tx,ty)).rgb;

				if (c.r < 0.1 && c.g < 0.1 && c.b < 0.1){
					isLine = true;
				}
			}
		}
		if (isLine){
			col.r = 0.0;
			col.g = 0.0;
			col.b = 0.0;
		}
	'

fragBlackAlwaysOpaque = ->
	return '
		if (col.r < 0.003 && col.g < 0.003 && col.b < 0.003){
			currentOpacity = 1.0;
		}
	'
