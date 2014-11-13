fs = require 'fs'
stlLoader = require '../src/client/plugins/stlImport/stlLoader.coffee'
expect = require('chai').expect

process.env.NODE_ENV = 'test'

describe 'stlImport', () ->
	models = []
	parsedModels = []

	before (done) ->
			models.push fs.readFileSync 'test/testmodel_googles.stl',
				{encoding: 'utf8'}
			models.push fs.readFileSync 'test/testmodel_house.stl',
				{encoding: 'utf8'}
			models.push fs.readFileSync 'test/testmodel_screwdriver.stl',
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
