fs = require 'fs'
path = require 'path'
winston = require 'winston'
stlLoader = require '../src/plugins/stlImport/stlLoader'
reportGenerator = require './reportGenerator'
mkdirp = require 'mkdirp'

Voxelizer = require '../src/plugins/faBrickator/geometry/Voxeliser'
BrickSystem = require '../src/plugins/faBrickator/bricks/BrickSystem'

lego = new BrickSystem(8, 8, 3.2, 1.7, 2.512)
lego.add_BrickTypes [
	[1,1,1],[1,2,1],[1,3,1],[1,4,1],[1,6,1],[1,8,1],[2,2,1],[2,3,1],
	[2,4,1],[2,6,1],[2,8,1],[2,10,1],[1,1,3],[1,2,3],[1,3,3],[1,4,3],
	[1,6,3],[1,8,3],[1,10,3],[1,12,3],[1,16,3],[2,2,3],[2,3,3],[2,4,3],
	[2,6,3],[2,8,3],[2,10,3]
]
voxelizer = new Voxelizer()

require('es6-promise').polyfill()

modelPath = path.join 'batchTesting', 'models'
outputPath = path.join 'batchTesting', 'results'
reportFile = 'batchTestResults'

# save temporary batch test report all X models
resultSavingFrequency = 15

beginDate = new Date()

logger = new (winston.Logger)({
	transports: [
		new winston.transports.Console { level: 'debug' }
	]
})

# Tests all models that are in the modelPath directory. Since there may be
# various models to test where the copyright state is unknown, you have to add
# the folder and models on your own.
# The (debug) output is saved to the debugLogFile, the test results are saved as
# as JSON in the testResultFile for further processing
module.exports.startTesting = () ->
	# create output directory if it does not exist
	mkdirp.sync(outputPath)

	logger.info 'starting batch testing'
	models = parseModelFiles()
	logger.info "Testing #{models.length} models"
	results = []
	modelCounter = 0

	testNextBatch models.length, models,results

testNextBatch = (numModels, modelArray, accumulatedResults) ->
	perc = (1.0 - (modelArray.length / numModels)) * 100
	perc = perc.toFixed 1
	logger.info "#{perc}%, testing next batch..."

	# get the next array of #resultSavingFrequency models
	testModels = []
	if modelArray.length < resultSavingFrequency
		for m in modelArray
			testModels.push m
		modelArray = []
	else
		for i in [0..resultSavingFrequency - 1]
			testModels.push modelArray[i]
		modelArray.splice(0,resultSavingFrequency)

	# test All
	testpromises = []
	for m in testModels
		testpromises.push testModel m

	# wait for all tests to complete
	p = Promise.all(testpromises)
	p.then (results) ->
		for r in results
			# add our current batch to existing results
			if r
				accumulatedResults.push r

		thisIsLastBatch = true if modelArray.length == 0

		# genrate a report
		if thisIsLastBatch
			logger.info 'Generating final test report'
		else
			logger.info "Generating temporary test report for #{perc}%-batch"

		reportPromise = reportGenerator.generateReport accumulatedResults,
			outputPath, reportFile, thisIsLastBatch, beginDate
		reportPromise.then () ->
			# after report generation: if there are models left, test the next
			# batch
			if not thisIsLastBatch
				testNextBatch numModels, modelArray, accumulatedResults


# parses all models in the modelPath directory
parseModelFiles = () ->
	if !fs.existsSync modelPath
		logger.warn '"models" folder does not exist, no models to load'
		return []
	else
		files = fs.readdirSync modelPath
		models = []

		for file in files
			if path.extname(file).toLowerCase() == '.stl'
				models.push file

		return models

# performs various tests on a single model
testModel = (filename) ->
	return new Promise (resolve, reject) ->
		testResult = new ModelTestResult()
		testResult.fileName = filename
		filepath = path.join(modelPath, filename)

		fs.readFile filepath, {encoding: 'utf8'}, (error, fileContent) ->
			if error
				reject(error)
				return

			begin = new Date()
			stlModel = stlLoader.parse fileContent,null,false,false

			if not stlModel
				logger.warn "Model '#{filename}' was not properly loaded"
				resolve(null)
				return

			testResult.stlParsingTime = new Date() - begin
			testResult.numStlParsingErrors = stlModel.importErrors.length
			logger.debug "model parsed in
			#{testResult.stlParsingTime}ms with
			#{testResult.numStlParsingErrors} Errors"

			begin = new Date()
			cleanseResult = stlModel.cleanse true
			testResult.stlCleansingTime = new Date() - begin
			testResult.stlDeletedPolygons = cleanseResult.deletedPolygons
			testResult.stlRecalculatedNormals = cleanseResult.recalculatedNormals
			logger.debug "model cleansed in
			#{testResult.stlCleansingTime}ms,
			#{cleanseResult.deletedPolygons} deleted Polygons and
			#{cleanseResult.recalculatedNormals} fixedNormals"

			begin = new Date()
			optimizedModel = stlLoader.optimizeModel stlModel
			testResult.optimizationTime  = new Date() - begin
			testResult.numPolygons = optimizedModel.indices.length / 3
			testResult.numPoints = optimizedModel.positions.length / 3
			logger.debug "model optimized in #{testResult.optimizationTime}ms"

			begin = new Date()
			if optimizedModel.isTwoManifold()
				testResult.isTwoManifold = 1
			else
				testResult.isTwoManifold = 0
			testResult.twoManifoldCheckTime = new Date() - begin
			logger.debug "checked 2-manifoldness in #{testResult.twoManifoldCheckTime}ms"

			begin = new Date()
			try
				voxelizer.voxelise optimizedModel, lego
				testResult.voxelizationTime = new Date() - begin
				logger.debug "voxelized in #{testResult.voxelizationTime}"
			catch
				logger.warn 'Error while voxelizing'
				testResult.voxelizationTime = -1

			resolve(testResult)

# This class holds all test results for one model and is
# saved (with other results) to the testResultFile
class ModelTestResult
	constructor: ->
		@stlParsingTime = 0
		@numStlParsingErrors = 0
		@stlCleansingTime = 0
		@stlDeletedPolygons = 0
		@stlRecalculatedNormals = 0
		@optimizationTime = 0
		@numPolygons = 0
		@numPoints = 0
		@isTwoManifold = 0
		@twoManifoldCheckTime = 0
		@voxelizationTime = 0
