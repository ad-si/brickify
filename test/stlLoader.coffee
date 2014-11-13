fs = require 'fs'
stlLoader = require '../src/client/plugins/stlImport/stlLoader.coffee'
expect = require('chai').expect

process.env.NODE_ENV = 'test'

describe 'stlImport', () ->
	modelPath = 'test/models/'
	models = []
	parsedModels = []

	before (done) ->
			files = fs.readdirSync modelPath
			for file in files
				if file.endsWith '.stl'
					models.push fs.readFileSync modelPath + file,
						{encoding: 'utf8'}
			done()

	describe 'stlImport', () ->
		it 'should load stl files, convert to the internal representation', (done) ->
			for model in models
				parsedModel = stlLoader.parse model
				expect(parsedModel.importErrors.length).to.equal(0)
				parsedModels.push parsedModel
			done()

	describe 'stlConvert', () ->
		it 'should convert the models to optimized geometry', (done) ->
			@timeout(10000)
			for model in parsedModels
				optGeo = stlLoader.optimizeModel model
			done()

	after () ->
