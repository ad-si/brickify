THREE = require 'three'
meshlib = require 'meshlib'
log = require 'loglevel'

modelCache = require '../../client/modelLoading/modelCache'
LegoPipeline = require './pipeline/LegoPipeline'
PipelineSettings = require './pipeline/PipelineSettings'
Brick = require './pipeline/Brick'
threeHelper = require '../../client/threeHelper'
Spinner = require '../../client/Spinner'

###
# @class NewBrickator
###
class NewBrickator
	constructor: ->
		@pipeline = new LegoPipeline()

	init: (@bundle) => return

	onNodeAdd: (node) =>
		@nodeVisualizer = @bundle.getPlugin 'nodeVisualizer'

		@runLegoPipeline node

	onNodeRemove: (node) =>
		@pipeline.terminate()

	runLegoPipeline: (selectedNode) =>
		Spinner.startOverlay @bundle.renderer.getDomElement()
		@_getCachedData(selectedNode)
		.then (cachedData) =>
			#since cached data already contains voxel grid, only run lego
			settings = new PipelineSettings(@bundle.globalConfig)
			settings.deactivateVoxelizing()

			settings.setModelTransform threeHelper.getTransformMatrix selectedNode

			data = {
				optimizedModel: cachedData.optimizedModel
				grid: cachedData.grid
			}

			@pipeline.run data, settings, true
			.then =>
				cachedData.csgNeedsRecalculation = true

				@nodeVisualizer?.objectModified selectedNode, cachedData
				Spinner.stop @bundle.renderer.getDomElement()
		.catch (error) =>
			log.error error
			Spinner.stop @bundle.renderer.getDomElement()

	###
	# If voxels have been selected as lego / as 3d print, the brick layout
	# needs to be locally regenerated
	# @param {Object} cachedData reference to cachedData
	# @param {Array<BrickObject>} modifiedVoxels list of voxels that have
	# been modified
	# @param {Boolean} createBricks creates Bricks if a voxel has no associated
	# brick. this happens when using the lego brush to create new bricks
	###
	relayoutModifiedParts: (selectedNode, modifiedVoxels, createBricks = false) =>
		log.debug 'relayouting modified parts, creating bricks:',createBricks
		@_getCachedData(selectedNode)
		.then (cachedData) =>
			modifiedBricks = new Set()
			for v in modifiedVoxels
				if v.brick
					modifiedBricks.add v.brick
				else if createBricks
					modifiedBricks.add new Brick([v])

			settings = new PipelineSettings(@bundle.globalConfig)
			settings.onlyRelayout()

			data = {
				optimizedModel: cachedData.optimizedModel
				grid: cachedData.grid
				modifiedBricks: modifiedBricks
			}

			@pipeline.run data, settings, true
			.then =>
				cachedData.csgNeedsRecalculation = true

				@nodeVisualizer?.objectModified selectedNode, cachedData
		.catch (error) ->
			log.error error

	everythingPrint: (selectedNode) =>
		@_getCachedData selectedNode
		.then (cachedData) =>
			settings = new PipelineSettings(@bundle.globalConfig)
			settings.onlyInitLayout()

			data = grid: cachedData.grid

			@pipeline.run data, settings, true
			.then =>
				cachedData.csgNeedsRecalculation = true

				@nodeVisualizer?.objectModified selectedNode, cachedData

	_createDataStructure: (selectedNode) =>
		selectedNode.getModel().then (model) =>
			# create grid
			settings = new PipelineSettings(@bundle.globalConfig)
			settings.setModelTransform threeHelper.getTransformMatrix selectedNode
			settings.deactivateLayouting()

			@pipeline.run(
				optimizedModel: model
				settings
				true
			)
			.then (results) ->
				# create data structure
				return {
					node: selectedNode
					grid: results.grid
					optimizedModel: model
					csgNeedsRecalculation: true
				}

	_checkDataStructure: (selectedNode, data) ->
		return yes # Later: Check for node transforms

	_getCachedData: (selectedNode) =>
		return selectedNode.getPluginData 'newBrickator'
		.then (data) =>
			if data? and @_checkDataStructure selectedNode, data
				return data
			else
				@_createDataStructure selectedNode
				.then (data) ->
					selectedNode.storePluginData 'newBrickator', data, true
					return data

	getDownload: (selectedNode, downloadOptions) =>
		options = @_prepareCSGOptions(
			downloadOptions.studRadius, downloadOptions.holeRadius
		)

		@csg ?= @bundle.getPlugin 'csg'
		if not @csg?
			log.warn 'Unable to create download due to CSG Plugin missing'
			return Promise.resolve { data: '', fileName: '' }

		dlPromise = new Promise (resolve, reject) =>
			@csg.getCSG selectedNode, options
			.then (detailedCsgGeometries) ->
				if not detailedCsgGeometries? or detailedCsgGeometries.length is 0
					resolve [{ data: '', fileName: '' }]
					return

				results = []

				for i in [0..detailedCsgGeometries.length - 1]
					geometry = detailedCsgGeometries[i]

					optimizedModel = new meshlib.OptimizedModel()
					optimizedModel.fromThreeGeometry(geometry)

					meshlib
					.model(optimizedModel)
					.export null, (error, binaryStl) ->
						fn = "brickify-#{selectedNode.name}"
						fn = fn.replace /.stl$/, ''
						fn += "-#{i}"
						fn += '.stl'
						results.push { data: binaryStl, fileName: fn }

					resolve results

			.catch (error) ->
				log.error error
				reject error

		return dlPromise

	_prepareCSGOptions: (studRadius, holeRadius) =>
		options = {}

		# set stud and hole size
		if studRadius?
			options.studSize = {
				radius: studRadius
				height: @bundle.globalConfig.studSize.height
			}

		if holeRadius?
			options.holeSize = {
				radius: holeRadius
				height: @bundle.globalConfig.holeSize.height
			}

		# add studs
		options.addStuds = true

		return options

	getHotkeys: =>
		return unless process.env.NODE_ENV is 'development'
		return {
			title: 'newBrickator'
			events: [
				{
					hotkey: 'c'
					description: 'cancel current pipeline operation'
					callback: => @pipeline.terminate()
				}
			]
		}

module.exports = NewBrickator
