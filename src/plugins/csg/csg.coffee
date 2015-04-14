CsgExtractor = require './CsgExtractor'
threeHelper = require '../../client/threeHelper'

class CSG
	###
	# Returns a promise which will, when resolved, provide
	# the volumetric subtraction of ModelGeometry - LegoBricks
	# as a THREE.Mesh
	#
	# @return {THREE.Mesh} the volumetric subtraction
	# @param {Object} options the options which may consist out of:
	# @param {Object} options.studSize radius and height of LEGO studs
	# @param {Object} options.holeSize radius and height of holes for
	# LEGO studs
	# @param {Boolean} options.addStuds whether studs are added at all
	###
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

	# returns own cached data and links grid from newBrickator data
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

	# Creates a CSG subtraction between the node - lego voxels from grid
	_createCSG: (cachedData, selectedNode, options) =>
		if not @_csgNeedsRecalculation cachedData, options
			return Promise.resolve cachedData.csg

		return @_prepareModel cachedData, selectedNode
		.then (threeModel) =>
			cachedData.transformedThreeModel = threeModel
			@csgExtractor ?= new CsgExtractor()

			options.profile = true
			options.transformedModel = cachedData.transformedThreeModel

			cachedData.csg = @csgExtractor.extractGeometry cachedData.grid, options

			return cachedData.csg

	# Converts the optimized model from the selected node to a three model
	# that is transformed to match the grid
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

	# determines whether the CSG operation needs recalculation
	_csgNeedsRecalculation: (cachedData, options) ->
		if not cachedData.oldOptions?
			return true

		newOptions = JSON.stringify options
		return false if cachedData.oldOptions == newOptions

		cachedData.oldOptions = newOptions
		return true



module.exports = CSG
