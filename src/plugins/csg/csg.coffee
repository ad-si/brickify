CsgExtractor = require './CsgExtractor'
threeHelper = require '../../client/threeHelper'
csgCleaner = require './csgCleaner'

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
	_applyDefaultValues: (options) ->
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

		if not options.minimalPrintVolume?
			options.minimalPrintVolume = 5

	# returns own cached data and links grid from newBrickator data
	# resets newBrickator's csgNeedsRecalculation flag
	_getCachedData: (selectedNode) ->
		return selectedNode.getPluginData 'csg'
		.then (data) ->
			if not data?
				# create empty data set for own data
				data = {}
				selectedNode.storePluginData 'csg', data, true

			#link grid and dirty flag from newBrickator
			return selectedNode.getPluginData 'newBrickator'
			.then (newBrickatorData) ->
				data.grid = newBrickatorData.grid
				data.csgNeedsRecalculation = true if newBrickatorData.csgNeedsRecalculation
				newBrickatorData.csgNeedsRecalculation = false
				# finally return own data + newBrickator grid
				return data

	# Creates a CSG subtraction between the node - lego voxels from grid
	_createCSG: (cachedData, selectedNode, options) =>
		if not @_csgNeedsRecalculation cachedData, options
			return Promise.resolve cachedData.csg

		return @_prepareModel cachedData, selectedNode
		.then (threeGeometry) =>
			cachedData.transformedthreeGeometry = threeGeometry
			@csgExtractor ?= new CsgExtractor()

			options.profile = true
			options.transformedModel = cachedData.transformedthreeGeometry

			result = @csgExtractor.extractGeometry cachedData.grid, options

			options.split = true
			options.filterSmallGeometries = !result.isOriginalModel
			cachedData.csg = csgCleaner.clean result.csg, options

			return cachedData.csg

	# Converts the optimized model from the selected node to a three model
	# that is transformed to match the grid
	_prepareModel: (cachedData, selectedNode) ->
		return new Promise (resolve, reject) ->
			if cachedData.transformedthreeGeometry?
				resolve(cachedData.transformedthreeGeometry, cachedData)
				return

			selectedNode.getModel()
			.then (model) ->
				threeGeometry = model.convertToThreeGeometry()
				threeGeometry.applyMatrix threeHelper.getTransformMatrix selectedNode
				resolve(threeGeometry)
			.catch (error) ->
				reject(error)

	# determines whether the CSG operation needs recalculation
	_csgNeedsRecalculation: (cachedData, options) ->
		newOptions = JSON.stringify options

		# check if options changed
		if not cachedData.oldOptions?
			cachedData.oldOptions = newOptions
			return true

		if cachedData.oldOptions != newOptions
			cachedData.oldOptions = newOptions
			return true

		cachedData.oldOptions = newOptions

		# check if there was a brush action that forces us
		# to recreate CSG
		if cachedData.csgNeedsRecalculation
			cachedData.csgNeedsRecalculation = false
			return true
		return false

module.exports = CSG
