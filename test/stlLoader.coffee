fs = require 'fs'
stlLoader = require '../src/client/plugins/stlImport/stlLoader.coffee'
expect = require('chai').expect

process.env.NODE_ENV = 'test'

describe 'stlImport', () ->
	modelPath = 'test/models/'
	models = []
	modelFiles = []
	parsedModels = []
	expectedWarnings = []
	shallOptimize = []

	before (done) ->
			#read all models and config files
			files = fs.readdirSync modelPath
			for file in files
				if file.endsWith '.stl'
					models.push fs.readFileSync modelPath + file,
						{encoding: 'utf8'}
					modelFiles.push modelPath + file

					jsonfile = file.substring(0, file.length - 4) + '.json'
					json = {}
					if fs.existsSync(modelPath + jsonfile)
						json = JSON.parse fs.readFileSync(modelPath + jsonfile)

					if json.expectedWarnings?
						expectedWarnings.push json.expectedWarnings
					else
						expectedWarnings.push 0

					if json.optimize?
						shallOptimize.push json.optimize
					else
						shallOptimize.push true
			done()

	describe 'stlImport', () ->
		it 'should load stl files, convert to the internal representation', (done) ->
			for i in [0..models.length - 1]
				console.log "Importing #{modelFiles[i]}"
				errorcallback = (error) ->
					console.log "-> Import Error: #{error}"
				parsedModel = stlLoader.parse models[i], errorcallback, false

				expect(parsedModel.importErrors.length).to.equals(expectedWarnings[i])
				parsedModels.push parsedModel
			done()

	describe 'stlConvert', () ->
		it 'should convert the models to optimized geometry', (done) ->
			totalBegin = new Date()
			@timeout(30000)

			for i in [0..modelFiles.length - 1]
				if !shallOptimize[i]
					continue
				console.log "Optimizing model #{modelFiles[i]}"
				console.log "--> Model has #{parsedModels[i].polygons.length}
				            Polygons"
				begin = new Date()
				optGeo = stlLoader.optimizeModel parsedModels[i]
				deltaTime = new Date - begin
				console.log "--> Model optimized in #{deltaTime} ms"

				numPoly = 0
				for m in parsedModels
					numPoly += m.polygons.length

				deltaTime = new Date() - totalBegin
				msPerPoly = deltaTime / numPoly

			console.log "All selected models have been
						optimized in #{new Date() - totalBegin} ms"

			console.log "It took #{(msPerPoly * 1000).toFixed 2} ms
						for 1000 Polygons"
			done()

	after () ->
		return undefined
