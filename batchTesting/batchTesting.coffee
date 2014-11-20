fs = require 'fs'
path = require 'path'
winston = require 'winston'
stlLoader = require '../src/client/plugins/stlImport/stlLoader'
reportGenerator = require './reportGenerator'

modelPath = path.join 'batchTesting', 'models'
debugLogFile = path.join 'batchTesting', 'results', 'batchTestDebug.log'
testResultFile = path.join 'batchTesting', 'results', 'batchTestResults.log'
reportFile = path.join 'batchTesting', 'results', 'batchTestResults.html'

logger = new (winston.Logger)({
	transports: [
		new winston.transports.Console { level: 'debug' },
		new winston.transports.File {
			name: 'debugfile'
			filename: debugLogFile
			level: 'debug'}
	]
})

resultLogger = new (winston.Logger)({
	transports: [
		new winston.transports.File {
			name: 'resultfile'
			filename: testResultFile
			level: 'info'}
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
	for model in models
		result = testModel model
		result.fileName = model
		resultLogger.info result
		results.push result

	if results.length == 0
		logger.warn 'No models where processed, test report can\'t be created'
	else
		reportGenerator.generateReport results, reportFile

# parses all models in the modelPath directory
parseModelFiles = () ->
	if !fs.existsSync modelPath
		logger.warn '"models" folder does not exist, no models to load'
		return []
	else
		files = fs.readdirSync modelPath
		return files

# performs various tests on a single model
testModel = (filename) ->
	logger.info "Testing model '#{filename}'"
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
