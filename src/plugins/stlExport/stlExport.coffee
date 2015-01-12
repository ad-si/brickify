###
  #STL Export Plugin#

  Converts any ThreeJS geometry to ASCII-.stl data format
###

$ = require 'jquery'
saveAs = require 'filesaver.js'

modelCache = require '../../client/modelCache'


module.exports = class StlExport

	constructor: () ->
		@$spinnerContainer = $('#spinnerContainer')

	generateAsciiStl: (optimizedModel) ->
		{indices, faceNormals, originalFileName, positions} = optimizedModel

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


	generateBinaryStl: (optimizedModel) ->
		isLittleEndian = true


	saveStl: (stlString, fileName) =>
		console.log(saveAs)
		blob = new Blob [stlString], {type: 'text/plain;charset=utf-8'}
		saveAs blob, fileName
		@$spinnerContainer.fadeOut()


	exportStl: (format) =>

		if format is 'ascii'
			generatorFunc = @generateAsciiStl

		else if format is 'binary'
			generatorFunc = @generateBinaryStl

		else
			throw new Error("Format '#{format}}' is not supported")

		@$spinnerContainer.fadeIn 'fast', () =>
			modelCache
			.request @node.meshHash
			.then (optimizedModel) =>
				@saveStl generatorFunc(optimizedModel),
					optimizedModel.originalFileName


	uiEnabled: (@node) ->
		return

	getUiSchema: () =>
		type: 'object'
		actions:
			exportAsciiStl:
				title: 'Export ASCII STL'
				callback: () => @exportStl('ascii')
			exportBinaryStl:
				title: 'Export Binary STL'
				callback: () => @exportStl('binary')
