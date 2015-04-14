CsgExtractor = require './CsgExtractor'
threeHelper = require '../../client/threeHelper'

class CSG
	constructor: -> return

	getCSG: (selectedNode, options = {}) =>
		@_applyDefaultValues options
		@_getCachedData(selectedNode)
		.then (cachedData) =>
			@_createCSG cachedData, selectedNode, options

	# applies default values if they don't exist yet
	_applyDefaultValues: (options) =>
		if not options.studSize?
			options.studSize = {
				radius: 2.4
				height: 1.8
			}

		if not options.holeSize?
			options.holeSize = {
				radius: 2.4
				height: 1.8
			}

		if not options.addStuds?
			options.addStuds = false

	_getCachedData: (selectedNode) =>
		return selectedNode.getPluginData 'csg'
		.then (data) =>
			return data if data?

			# create empty dataset for own data
			data = {}
			selectedNode.storePluginData 'csg', data, true

			#link grid from newBrickator
			return selectedNode.getPluginData 'newBrickator'
			.then (newBrickatorData) =>
				data.grid = newBrickatorData.grid
				# finally return own data + newBrickator grid
				return data

	_createCSG: (cachedData, selectedNode, options) =>
		if not @_csgNeedsRecalculation cachedData, options
			return Promise.resolve cachedData.csg

		return @_prepareModel cachedData, selectedNode
		.then (threeModel) =>
			cachedData.transformedThreeModel = threeModel
			@csgExtractor ?= new CsgExtractor()

			console.log "Csg options: " + JSON.stringify options
			options.profile = true
			options.transformedModel = cachedData.transformedThreeModel

			cachedData.csg = @csgExtractor.extractGeometry cachedData.grid, options

			return cachedData.csg

	_prepareModel: (cachedData, selectedNode) =>
		return new Promise (resolve, reject) =>
			if cachedData.transformedThreeModel?
				resolve(cachedData.transformedThreeModel)
				return

			selectedNode.getModel()
			.then (model) =>
				threeModel = model.convertToThreeGeometry()
				threeModel.applyMatrix threeHelper.getTransformMatrix selectedNode
				resolve(threeModel)
			.catch (error) =>
				reject(error)

	_csgNeedsRecalculation: (cachedData, options) ->
		if not cachedData.oldOptions?
			return true

		newOptions = JSON.stringify options
		return false if cachedData.oldOptions == newOptions

		cachedData.oldOptions = newOptions
		return true



module.exports = CSG
