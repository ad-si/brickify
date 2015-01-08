###
  #STL Export Plugin#

  Converts any ThreeJS geometry to ASCII-.stl data format
###

$ = require 'jquery'
jqtree = require 'jqtree'

modelCache = require '../../client/modelCache'

module.exports = class StlExport

	constructor: () ->
		@$spinnerContainer = $('#spinnerContainer')

	generateAsciiStl: (optimizedModel) ->
		{indices, faceNormals, originalFileName, positions} = optimizedModel

		stringifyFaceNormal = (i) ->
			faceNormals[(i * 3)] + ' ' +
			faceNormals[(i * 3) + 1] + ' ' +
			faceNormals[(i * 3) + 2]

		stringifyVector = (i) ->
			positions[(i * 3)] + ' ' +
			positions[(i * 3) + 1] + ' ' +
			positions[(i * 3) + 2]


		stl = "solid #{originalFileName}\n"

		for i in [0..indices.length - 1] by 3
			stl +=
				"facet normal #{stringifyFaceNormal(i / 3)}\n" +
				'\touter loop\n' +
				"\t\tvertex #{stringifyVector(indices[i])}\n" +
				"\t\tvertex #{stringifyVector(indices[i + 1])}\n" +
				"\t\tvertex #{stringifyVector(indices[i + 2])}\n" +
				'\tendloop\n' +
				'endfacet\n'

		stl += "endsolid #{originalFileName}\n"

	saveStl: (optimizedModel) ->
		stlString = @generateAsciiStl(optimizedModel)
		blob = new Blob [stlString], {type: 'text/plain;charset=utf-8'}
		saveAs blob, optimizedModel.originalFileName
		@$spinnerContainer.fadeOut()

	uiEnabled: (@node) ->
		return

	getUiSchema: () =>
		exportStl = () =>
			@$spinnerContainer.fadeIn 'fast', () =>
				modelCache
					.request @node.meshHash
					.then (optimizedModel) =>
						# TODO: Use webworkers to generate stl
						@saveStl optimizedModel

		type: 'object'
		actions:
			exportStl:
				title: 'Export STL'
				callback: exportStl
