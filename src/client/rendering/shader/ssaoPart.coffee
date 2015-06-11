# mainly inspired from http://theorangeduck.com/page/pure-depth-ssao

ShaderPart = require './shaderPart'

class SsaoPart extends ShaderPart
	getVertexVariables: ->
		return ''

	getVertexPreMain: ->
		return ''

	getVertexInMain: ->
		return''

	getFragmentVariables: ->
		return '
			uniform sampler2D tRandom;
		'

	getFragmentPreMain: ->
		return '
			float linearizeDepth(float depth){
				float zNear = 0.1;
				float zFar = 2500.0;
				return 2.0 * zNear  / (zFar + zNear - depth * (zFar - zNear));
			}

			vec3 ssaoNormalFromDepth(float depth, vec2 texCoords){
				vec2 offset1 = vec2(0.0, 0.001);
				vec2 offset2 = vec2(0.001, 0.0);

				float depth1 = linearizeDepth(texture2D(tDepth, texCoords + offset1).r);
				float depth2 = linearizeDepth(texture2D(tDepth, texCoords + offset2).r);

				vec3 p1 = vec3(offset1, depth1 - depth);
				vec3 p2 = vec3(offset2, depth2 - depth);

				vec3 normal = cross(p1, p2);
				normal.z = -normal.z;
				return normalize(normal);
			}\n

			#define SSAO_SAMPLES 16\n

			float ssaoCalculate(vec2 texCoords){\n
				const float total_strength = 1.0;\n
				const float base = 0.2;\n

				const float area = 0.0075;\n
				const float falloff = 0.0005;\n

				const float radius = 0.008;\n

				vec3 sample_sphere[SSAO_SAMPLES];
				sample_sphere[ 0] = vec3( 0.5381, 0.1856,-0.4319);
				sample_sphere[ 1] = vec3( 0.1379, 0.2486, 0.4430);
				sample_sphere[ 2] = vec3( 0.3371, 0.5679,-0.0057);
				sample_sphere[ 3] = vec3(-0.6999,-0.0451,-0.0019);
				sample_sphere[ 4] = vec3( 0.0689,-0.1598,-0.8547);
				sample_sphere[ 5] = vec3( 0.0560, 0.0069,-0.1843);
				sample_sphere[ 6] = vec3(-0.0146, 0.1402, 0.0762);
				sample_sphere[ 7] = vec3( 0.0100,-0.1924,-0.0344);
				sample_sphere[ 8] = vec3(-0.3577,-0.5301,-0.4358);
				sample_sphere[ 9] = vec3(-0.3169, 0.1063, 0.0158);
				sample_sphere[10] = vec3( 0.0103,-0.5869, 0.0046);
				sample_sphere[11] = vec3(-0.0897,-0.4940, 0.3287);
				sample_sphere[12] = vec3( 0.7119,-0.0154,-0.0918);
				sample_sphere[13] = vec3(-0.0533, 0.0596,-0.5411);
				sample_sphere[14] = vec3( 0.0352,-0.0631, 0.5460);
				sample_sphere[15] = vec3(-0.4776, 0.2847,-0.0271);

				float depth = linearizeDepth(texture2D( tDepth, texCoords ).r);

  				vec3 random = normalize(texture2D(tRandom,texCoords * (7.0 + depth)).rgb);

  				vec3 position = vec3(texCoords, depth);
  				vec3 normal = ssaoNormalFromDepth(depth, texCoords);

  				float radius_depth = radius / depth;
  				float occlusion = 0.0;

  				for (int i = 0; i < SSAO_SAMPLES; i++){
  					vec3 ray = radius_depth * reflect(sample_sphere[i], random);
  					vec3 hemi_ray = position + sign(dot(ray, normal)) * ray;

  					float occ_depth =  linearizeDepth(texture2D(tDepth, clamp(hemi_ray.xy,0.0,1.0)).r);
  					float difference = depth - occ_depth;

  					occlusion += step(falloff, difference) *
  					(1.0 - smoothstep(falloff, area, difference));
  				}\n

  				float ao = 1.0 - total_strength * occlusion * (1.0 / float(SSAO_SAMPLES));
  				return clamp(ao + base, 0.0, 1.0);
			}\n
		'

	getFragmentInMain: ->
		return '
			float ssao = ssaoCalculate(vUv);
			float ssaoDepth = linearizeDepth(texture2D(tDepth, vUv).r);
			vec3 normal = ssaoNormalFromDepth(ssaoDepth, vUv);
			
			/*normal = normal * 0.5 + 0.5;
    		col = vec4(normal.rgb, 1.0);*/

			col = vec4( ssao, ssao, ssao, 1.0 );
			/*col = col * 0.3 + (col * ssao * 0.7);*/
		'

#cameraNearPlane: 0.1
#cameraFarPlane: 2500

module.exports = SsaoPart
