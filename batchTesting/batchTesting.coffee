fs = require 'fs'
winston = require 'winston'
stlLoader = require '../src/client/plugins/stlImport/stlLoader.coffee'

modelPath = './batchTesting/models/'

logger = new (winston.Logger)({
	transports: [
		new winston.transports.Console { level: 'debug' },
		new winston.transports.File {
			name: 'debugfile'
			filename: 'batchTestDebug.log'
			level: 'debug'}
	]
})

resultLogger = new (winston.Logger)({
	transports: [
		new winston.transports.File {
			name: 'resultfile'
			filename: 'batchTestResults.log'
			level: 'info'}
	]
})


module.exports.startTesting = () ->
	logger.info 'starting batch testing'
	models = parseModelFiles()
	logger.info "Testing #{models.length} models"
	for model in models
		result = testModel model
		result.fileName = model
		resultLogger.info result

parseModelFiles = () ->
	if !fs.existsSync modelPath
		logger.warn '"models" folder does not exist, no models to load'
		return []
	else
		files = fs.readdirSync modelPath
		return files

testModel = (filename) ->
	logger.info "Testing model '#{filename}'"
	testResult = new ModelTestResult()
	fileContent = fs.readFileSync modelPath + filename, {encoding: 'utf8'}

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

	return testResult

class ModelTestResult
	constructor: ->
		@stlParsingTime = 0
		@numStlParsingErrors = 0
		@stlCleansingTime = 0
		@stlDeletedPolygons = 0
		@stlRecalculatedNormals = 0