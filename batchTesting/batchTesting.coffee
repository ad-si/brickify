require 'string.prototype.endswith'
require('es6-promise').polyfill()

fs = require 'fs'
path = require 'path'
util = require 'util'
stream = require 'stream'

fsp = require 'fs-promise'
winston = require 'winston'
mkdirp = require 'mkdirp'

meshlib = require '../modules/meshlib'
reportGenerator = require './reportGenerator',
#LegoPipeline = require '../src/plugins/newBrickator/LegoPipeline'


#legoPipeline = new LegoPipeline({length: 8, width: 8, height: 3.2})
modelPath = path.join __dirname, 'models'
outputPath = path.join __dirname, 'results'
models = []
jsonStream = null
htmlStream = null
logger = new winston.Logger({
	transports: [
		new winston.transports.Console {
			level: 'info'
			colorize: 'true'
		}
	]
})


getDateTimeString = () ->
	return (new Date)
		.toJSON()
		.slice(0, -8)
		.replace(':', '') + 'Z'


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
		@hullVoxelizationTime = 0
		@volumeFillTime = 0


tryToWrite = (testResult) ->
	if jsonStream.write(JSON.stringify(testResult, null, 2) + ',\n')

		if testResult.number < (models.length - 1)
			testModel(++testResult.number)
		else
			jsonStream.end()

	else
		jsonStream.once 'drain', -> tryToWrite(testResult)


testModel = (number) ->
	logger.info models[number]

	fileContent = fs.readFileSync path.join(__dirname, 'models', models[number])

	begin = new Date()

	meshlib.parse fileContent, null, (error, meshModel) ->
		if error
			throw error

		if not meshModel
			throw new Error "Model '#{modelPath}' was not properly loaded"

		testResult = {
			path: modelPath,
			number: number,
			stlParsingTime: new Date() - begin,
			numStlParsingErrors: 0,
			stlCleansingTime: 0,
			stlDeletedPolygons: 0,
			stlRecalculatedNormals: 0,
			optimizationTime: 0,
			numPolygons: 0,
			numPoints: 0,
			isTwoManifold: 0,
			twoManifoldCheckTime: 0,
			hullVoxelizationTime: 0,
			volumeFillTime: 0
		}

		logger.debug "Testing model '#{modelPath}'"
		#testResult.numStlParsingErrors = meshModel.importErrors.length
		logger.debug "model parsed in #{testResult.stlParsingTime}ms with"
		#{testResult.numStlParsingErrors} Errors"

		#	begin = new Date()
		#	cleanseResult = meshModel.cleanse true
		#	testResult.stlCleansingTime = new Date() - begin
		#	testResult.stlDeletedPolygons = cleanseResult.deletedPolygons
		#	testResult.stlRecalculatedNormals = cleanseResult.recalculatedNormals
		#	logger.debug "model cleansed in
		#			#{testResult.stlCleansingTime}ms,
		#			#{cleanseResult.deletedPolygons} deleted Polygons and
		#			#{cleanseResult.recalculatedNormals} fixedNormals"

		#	begin = new Date()
		#	optimizedModel = meshlib.optimizeModel meshModel
		#	testResult.optimizationTime  = new Date() - begin
		#	testResult.numPolygons = optimizedModel.indices.length / 3
		#	testResult.numPoints = optimizedModel.positions.length / 3
		#	logger.debug "model optimized in #{testResult.optimizationTime}ms"

		# begin = new Date()
		# if meshModel.isTwoManifold()
		# 	testResult.isTwoManifold = 1
		# else
		# 	testResult.isTwoManifold = 0
		# testResult.twoManifoldCheckTime = new Date() - begin
		# logger.debug "checked 2-manifoldness in
		# {testResult.twoManifoldCheckTime}ms"
		#
		# results = legoPipeline.run meshModel, {voxelResolution: 8}, true
		# testResult.hullVoxelizationTime = results.profilingResults[0]
		# testResult.volumeFillTime = results.profilingResults[1]

		# Don't really know why this timeout is necessary
		# TODO: Fix this with write.cork & uncork in next version of node
		setTimeout -> tryToWrite(testResult)


# Tests all models that are in the modelPath directory. Since there may be
# various models to test where the copyright state is unknown, you have to add
# the folder and models on your own.
# The (debug) output is saved to the debugLogFile, the test results are saved as
# as JSON in the testResultFile for further processing
module.exports.startTesting = () ->
	mkdirp.sync(outputPath)

	dateTime = getDateTimeString()

	logger.add winston.transports.File, {
		level: 'silly'
		json: false,
		filename: path.join outputPath, dateTime + '.log'
	}


	htmlPath = path.join __dirname, 'results', dateTime + '.html'
	htmlStream = fs.createWriteStream htmlPath, {encoding: 'utf-8'}
	htmlStream.on 'error', (error) ->
		throw error

	jsonPath = path.join __dirname, 'results', dateTime + '.json'
	jsonStream = fs.createWriteStream jsonPath, {encoding: 'utf-8'}
	jsonStream.on 'error', (error) ->
		throw error
	jsonStream.on 'open', () ->
		logger.info 'Starting batch-test'

		models = fs
		.readdirSync(modelPath)
		.filter (file) -> file.endsWith('.stl')

		logger.info "Testing #{models.length} models"

		testModel(0)
