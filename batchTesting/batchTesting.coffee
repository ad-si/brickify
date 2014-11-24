fs = require 'fs'
path = require 'path'
winston = require 'winston'
stlLoader = require '../src/client/plugins/stlImport/stlLoader'
reportGenerator = require './reportGenerator'

modelPath = path.join 'batchTesting', 'models'
outputPath = path.join 'batchTesting', 'results'
reportFile = 'batchTestResults'

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
	logger.info 'starting batch testing'
	models = parseModelFiles()
	logger.info "Testing #{models.length} models"
	results = []
	for i in [0..models.length - 1] by 1
		model = models[i]

		perc = (i + 1) / models.length * 100
		perc = perc.toFixed(1)

		logger.info "#{perc}% Testing model '#{model}'"
		result = testModel model
		result.fileName = model
		results.push result

	if results.length == 0
		logger.warn 'No models where processed, test report can\'t be created'
	else
		reportGenerator.generateReport results, outputPath, reportFile

# parses all models in the modelPath directory
parseModelFiles = () ->
	if !fs.existsSync modelPath
		logger.warn '"models" folder does not exist, no models to load'
		return []
	else
		files = fs.readdirSync modelPath
		models = []

		for file in files
			if file.toLowerCase().indexOf('.stl') > 0
				models.push file

		return models

# performs various tests on a single model
testModel = (filename) ->
	testResult = new ModelTestResult()
	filepath = path.join(modelPath, filename)
	fileContent = fs.readFileSync filepath, {encoding: 'utf8'}

	begin = new Date()
	stlModel = stlLoader.parse fileContent,null,false,false
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
	logger.debug "model optimized in #{testResult.optimizationTime}ms"

	begin = new Date()
	if optimizedModel.isTwoManifold()
		testResult.isTwoManifold = 1
	else
		testResult.isTwoManifold = 0
	testResult.twoManifoldCheckTime = new Date() - begin
	logger.debug "checked 2-manifoldness in #{testResult.twoManifoldCheckTime}ms"

	return testResult

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
		@isTwoManifold = 0
		@twoManifoldCheckTime = 0
