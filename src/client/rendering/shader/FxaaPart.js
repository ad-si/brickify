import ShaderPart from "./ShaderPart.js"

export default class FxaaPart extends ShaderPart {
  getVertexVariables () {
    return "\
varying vec2 v_rgbNW; \
varying vec2 v_rgbNE; \
varying vec2 v_rgbSW; \
varying vec2 v_rgbSE; \
varying vec2 v_rgbM;\
"
  }

  getVertexPreMain () {
    return "\
void texcoords(vec2 fragCoord, vec2 resolution, \
out vec2 v_rgbNW, out vec2 v_rgbNE, \
out vec2 v_rgbSW, out vec2 v_rgbSE, \
out vec2 v_rgbM) { \
vec2 inverseVP = 1.0 / resolution.xy; \
v_rgbNW = (fragCoord + vec2(-1.0, -1.0)) * inverseVP; \
v_rgbNE = (fragCoord + vec2(1.0, -1.0)) * inverseVP; \
v_rgbSW = (fragCoord + vec2(-1.0, 1.0)) * inverseVP; \
v_rgbSE = (fragCoord + vec2(1.0, 1.0)) * inverseVP; \
v_rgbM = vec2(fragCoord * inverseVP); \
}\
"
  }

  getVertexInMain () {
    return "\
vec2 texSize = vec2( texWidth, texHeight );\n \
vec2 fragCoord = vUv * texSize;\n \
texcoords(fragCoord, texSize, v_rgbNW, v_rgbNE, v_rgbSW, v_rgbSE, v_rgbM);\
"
  }

  getFragmentVariables () {
    return "\
varying vec2 v_rgbNW; \
varying vec2 v_rgbNE; \
varying vec2 v_rgbSW; \
varying vec2 v_rgbSE; \
varying vec2 v_rgbM;\
"
  }

  getFragmentPreMain () {
    return "\
/** \
Basic FXAA implementation based on the code on geeks3d.com with the \
modification that the texture2DLod stuff was removed since its \
unsupported by WebGL. \
-- \
From: \
https://github.com/mitsuhiko/webgl-meincraft \
Copyright (c) 2011 by Armin Ronacher. \
Some rights reserved. \
Redistribution and use in source and binary forms, with or without \
modification, are permitted provided that the following conditions are \
met: \
* Redistributions of source code must retain the above copyright \
notice, this list of conditions and the following disclaimer. \
* Redistributions in binary form must reproduce the above \
copyright notice, this list of conditions and the following \
disclaimer in the documentation and/or other materials provided \
with the distribution. \
* The names of the contributors may not be used to endorse or \
promote products derived from this software without specific \
prior written permission. \
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT \
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR \
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT \
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, \
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT \
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, \
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY \
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT \
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE \
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. \
*/ \
\
#ifndef FXAA_REDUCE_MIN\n \
#define FXAA_REDUCE_MIN (1.0/ 128.0)\n \
#endif\n \
#ifndef FXAA_REDUCE_MUL\n \
#define FXAA_REDUCE_MUL (1.0 / 8.0)\n \
#endif\n \
#ifndef FXAA_SPAN_MAX\n \
#define FXAA_SPAN_MAX 8.0\n \
#endif\n \
\
vec4 fxaa(sampler2D tex, vec2 fragCoord, vec2 resolution, \
vec2 v_rgbNW, vec2 v_rgbNE, \
vec2 v_rgbSW, vec2 v_rgbSE, \
vec2 v_rgbM) { \
vec4 color; \
mediump vec2 inverseVP = vec2(1.0 / resolution.x, 1.0 / resolution.y); \
vec3 rgbNW = texture2D(tex, v_rgbNW).xyz; \
vec3 rgbNE = texture2D(tex, v_rgbNE).xyz; \
vec3 rgbSW = texture2D(tex, v_rgbSW).xyz; \
vec3 rgbSE = texture2D(tex, v_rgbSE).xyz; \
vec4 texColor = texture2D(tex, v_rgbM); \
vec3 rgbM = texColor.xyz; \
vec3 luma = vec3(0.299, 0.587, 0.114); \
float lumaNW = dot(rgbNW, luma); \
float lumaNE = dot(rgbNE, luma); \
float lumaSW = dot(rgbSW, luma); \
float lumaSE = dot(rgbSE, luma); \
float lumaM = dot(rgbM, luma); \
float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE))); \
float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE))); \
mediump vec2 dir; \
dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE)); \
dir.y = ((lumaNW + lumaSW) - (lumaNE + lumaSE)); \
float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * \
(0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN); \
float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce); \
dir = min(vec2(FXAA_SPAN_MAX, FXAA_SPAN_MAX), \
max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX), \
dir * rcpDirMin)) * inverseVP; \
vec3 rgbA = 0.5 * ( \
texture2D(tex, fragCoord * inverseVP + dir * (1.0 / 3.0 - 0.5)).xyz + \
texture2D(tex, fragCoord * inverseVP + dir * (2.0 / 3.0 - 0.5)).xyz); \
vec3 rgbB = rgbA * 0.5 + 0.25 * ( \
texture2D(tex, fragCoord * inverseVP + dir * -0.5).xyz + \
texture2D(tex, fragCoord * inverseVP + dir * 0.5).xyz); \
float lumaB = dot(rgbB, luma); \
if ((lumaB < lumaMin) || (lumaB > lumaMax)){ \
color = vec4(rgbA, texColor.a); \
} \
else{ \
color = vec4(rgbB, texColor.a); \
} \
return color; \
}\
"
  }

  getFragmentInMain () {
    return "\
vec2 texSize = vec2( texWidth, texHeight );\n \
vec2 fragCoord = vUv * texSize; \
vec4 colFxaa = fxaa( \
tColor, fragCoord, texSize, v_rgbNW, \
v_rgbNE, v_rgbSW, v_rgbSE, v_rgbM);\n \
col.r = colFxaa.r; \
col.g = colFxaa.g; \
col.b = colFxaa.b;\
"
  }
}
