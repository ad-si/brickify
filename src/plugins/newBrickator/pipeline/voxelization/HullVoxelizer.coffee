Grid = require '../Grid'
log = require 'loglevel'

floatDelta = 1e-10
voxelRoundingThreshold = 1e-5

HullVoxelWorker = require './HullVoxelWorker'

module.exports = class Voxelizer
	constructor: ->
		@voxelGrid = null

	_addDefaults: (options) ->
		options.accuracy ?= 16
		options.zTolerance ?= 0.01

	voxelize: (model, options = {}, progressCallback) =>
		@_addDefaults options

		return new Promise (resolve, reject) =>
			return @setupGrid model, options
				.then (voxelGrid) =>

					lineStepSize = voxelGrid.heightRatio / options.accuracy

					progressAndFinishedCallback = (message) =>
						if message.state is 'progress'
							progressCallback message.progress
						else # if state is 'finished'
							resolve(
								grid: voxelGrid
								gridPOJO: message.data
							)

					@_getOptimizedVoxelSpaceModel model, options
					.then (voxelSpaceModel) =>
						@worker = @_getWorker()
						@worker.voxelize(
							voxelSpaceModel
							lineStepSize
							floatDelta
							voxelRoundingThreshold
							progressAndFinishedCallback
						)
				.catch (error) ->
					reject console.error

	terminate: =>
		@worker?.terminate()
		@worker = null

	_getOptimizedVoxelSpaceModel: (model, options) =>
		return model
			.getFaceVertexMesh()
			.then (faceVertexMesh) =>
				coordinates = faceVertexMesh.vertexCoordinates
				voxelSpaceCoordinates = new Array coordinates.length
				for i in [0...coordinates.length] by 3
					position =
						x: coordinates[i]
						y: coordinates[i + 1]
						z: coordinates[i + 2]
					coordinate = @voxelGrid.mapModelToVoxelSpace position
					voxelSpaceCoordinates[i] = coordinate.x
					voxelSpaceCoordinates[i + 1] = coordinate.y
					voxelSpaceCoordinates[i + 2] = coordinate.z

				normals = faceVertexMesh.faceNormalCoordinates
				directions = new Array normals.length / 3
				for i in [0...normals.length / 3] by 1
					directions[i] = normals[i * 3 + 2]

				return {
					coordinates: voxelSpaceCoordinates
					faceVertexIndices: faceVertexMesh.faceVertexIndices
					directions: directions
				}

	_getWorker: ->
		return @worker if @worker?
		return operative HullVoxelWorker

	setupGrid: (model, options) ->
		@voxelGrid = new Grid(options.gridSpacing)

		return @voxelGrid
		.setUpForModel model, options
		.then =>
			return @voxelGrid
