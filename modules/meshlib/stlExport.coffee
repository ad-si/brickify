saveAs = require 'filesaver.js'

toAsciiStl = (model) ->
	{faceNormals, indices, positions, originalFileName} = model

	stringifyFaceNormal = (i) ->
		faceNormals[i] + ' ' +
			faceNormals[i + 1] + ' ' +
			faceNormals[i + 2]

	stringifyVector = (i) ->
		positions[(i * 3)] + ' ' +
			positions[(i * 3) + 1] + ' ' +
			positions[(i * 3) + 2]


	stl = "solid #{originalFileName}\n"

	for i in [0...indices.length] by 3
		stl +=
			"facet normal #{stringifyFaceNormal(i)}\n" +
				'\touter loop\n' +
				"\t\tvertex #{stringifyVector(indices[i])}\n" +
				"\t\tvertex #{stringifyVector(indices[i + 1])}\n" +
				"\t\tvertex #{stringifyVector(indices[i + 2])}\n" +
				'\tendloop\n' +
				'endfacet\n'

	stl += "endsolid #{originalFileName}\n"

	new Blob [stl], {type: 'text/plain;charset=utf-8'}


toBinaryStl = (model) ->
	{faceNormals, indices, positions} = model

	# Length in byte
	headerLength = 80 # 80 * uint8
	facetsCounterLength = 4 # 1 * uint32
	vectorLength = 12 # 3 * float32
	attributeByteCountLength = 2 # 1 * uint16
	facetLength = (vectorLength * 4 + attributeByteCountLength)
	contentLength = (indices.length / 3) * facetLength
	bufferLength = headerLength + facetsCounterLength + contentLength

	buffer = new ArrayBuffer(bufferLength)
	dataView = new DataView(buffer, headerLength)
	le = true # little-endian

	dataView.setUint32(0, (indices.length / 3), le)
	offset = facetsCounterLength

	for i in [0...indices.length] by 3
		# Normal
		dataView.setFloat32(offset, faceNormals[i], le)
		dataView.setFloat32(offset += 4, faceNormals[i + 1], le)
		dataView.setFloat32(offset += 4, faceNormals[i + 2], le)

		# X,Y,Z-Vector
		for a in [0..2]
			dataView.setFloat32(
				offset += 4, positions[indices[i + a] * 3], le
			)
			dataView.setFloat32(
				offset += 4, positions[indices[i + a] * 3 + 1], le
			)
			dataView.setFloat32(
				offset += 4, positions[indices[i + a] * 3 + 2], le
			)

		# Attribute Byte Count
		dataView.setUint16(offset += 4, 0, le)
		offset += 2

	new Blob [buffer]


saveAsBinaryStl = (model) =>

	saveAs toBinaryStl(model), model.fileName


saveAsAsciiStl = (model) =>

	saveAs toAsciiStl(model), model.fileName


module.exports =
	toAsciiStl: toAsciiStl
	toBinaryStl: toBinaryStl
	saveAsBinaryStl: saveAsBinaryStl
	saveAsAsciiStl: saveAsAsciiStl
