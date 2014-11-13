fs = require 'fs'
stlLoader = require '../src/client/plugins/stlImport/stlLoader.coffee'
expect = require('chai').expect

process.env.NODE_ENV = 'test'

describe 'stlImport', () ->

	models = []
	parsedModels = []
	modelFiles = [
		'test/testmodel_googles.stl'
		'test/testmodel_house.stl'
		'test/testmodel_microphone.stl'
		'test/testmodel_screwdriver.stl'
	]
	expectedWarnings = [0,0,1,1]
	shallOptimize = [true,true,true,false]
	before (done) ->
		for file in modelFiles
			models.push fs.readFileSync file, {encoding: 'utf8'}
		done()

	describe 'stlImport', () ->
		it 'should load stl files, convert to the internal representation', (done) ->
			for i in [0..modelFiles.length-1]
				console.log "Importing "  + modelFiles[i]
				parsedModel = stlLoader.parse models[i], (error) ->
					console.log "-> Import Error: " + error

				expect(parsedModel.importErrors.length).to.equals(expectedWarnings[i])
				parsedModels.push parsedModel
			done()

	describe 'stlConvert', () ->
		it 'should convert the models to optimized geometry', (done) ->
			@timeout(30000)
			for i in [0..modelFiles.length-1]
				if !shallOptimize[i]
					continue
				console.log "Optimizing model " + modelFiles[i]
				console.log "--> Model has #{parsedModels[i].polygons.length} Polygons"
				begin = new Date()
				optGeo = stlLoader.optimizeModel parsedModels[i]
				deltaTime = new Date - begin
				console.log "--> Model optimized in #{deltaTime}ms"
			done()

	after () ->
