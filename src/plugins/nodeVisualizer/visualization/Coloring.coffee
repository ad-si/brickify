THREE = require 'three'
LineMatGenerator = require './LineMatGenerator'

# Provides a simple implementation on how to color voxels and bricks
module.exports = class Coloring
	constructor: (@globalConfig) ->
		@brickMaterial = new THREE.MeshLambertMaterial({
			color: 0xfff000 #orange
		})

		@selectedMaterial = new THREE.MeshLambertMaterial({
			color: 0xff0000
		})

		@hiddenMaterial = new THREE.MeshLambertMaterial({
			color: 0xffaaaa #gray
			opacity: 0.0
			transparent: true
		})

		@legoHighlightMaterial = new THREE.MeshLambertMaterial({
			color: 0xff7755
		})

		@printHighlightMaterial = new THREE.MeshLambertMaterial({
			color: 0xeeeeee
		})

		@legoBoxHighlightMaterial = new THREE.MeshLambertMaterial({
			color: 0xff7755
			opacity: 0.5
			transparent: true
		})

		@printBoxHighlightMaterial = new THREE.MeshLambertMaterial({
			color: 0xeeeeee
			opacity: 0.4
			transparent: true
		})

		@csgMaterial = new THREE.MeshLambertMaterial({
			color: 0xb5ffb8 #greenish gray
		})

		@legoShadowMat = new THREE.MeshBasicMaterial({
			color: 0x303030
			transparent: true
			opacity: 0.3
		})
		@legoShadowMat.polygonOffset = true
		@legoShadowMat.polygonOffsetFactor = -2
		@legoShadowMat.polygonOffsetUnits = -2

		# object visualization
		# default object material
		@objectMaterial = new THREE.MeshLambertMaterial(
			color: @globalConfig.colors.object
			ambient: @globalConfig.colors.object
		)

		# printed object material
		@objectPrintMaterial = new THREE.MeshLambertMaterial({
			color: 0xeeeeee
			opacity: 0.8
			transparent: true
		})

		# remove z-Fighting on baseplate
		@objectPrintMaterial.polygonOffset = true
		@objectPrintMaterial.polygonOffsetFactor = 3
		@objectPrintMaterial.polygonOffsetUnits = 3

		@objectShadowMat = new THREE.MeshBasicMaterial(
			color: 0x000000
			transparent: true
			opacity: 0.4
			depthFunc: THREE.GreaterDepth
		)
		@objectShadowMat.polygonOffset = true
		@objectShadowMat.polygonOffsetFactor = 3
		@objectShadowMat.polygonOffsetUnits = 3

		lineMaterialGenerator = new LineMatGenerator()
		@objectLineMat = lineMaterialGenerator.generate 0x000000
		@objectLineMat.linewidth = 2
		@objectLineMat.transparent = true
		@objectLineMat.opacity = 0.1
		@objectLineMat.depthFunc = THREE.GreaterDepth
		@objectLineMat.depthWrite = false

		@_createBrickMaterials()

	setPipelineMode: (enabled) =>
		if enabled
			@objectPrintMaterial.transparent = false

			@objectShadowMat.visible = false
			@objectLineMat.transparent = false
			@objectLineMat.depthWrite = true
			@objectLineMat.depthFunc = THREE.LessEqualDepth

			@legoBoxHighlightMaterial.transparent = false
			@printBoxHighlightMaterial.transparent = false
			@objectPrintMaterial.transparent = false
			@legoShadowMat.transparent = false
		else
			@objectPrintMaterial.transparent = true

			@objectShadowMat.visible = true
			@objectLineMat.transparent = true
			@objectLineMat.depthWrite = false
			@objectLineMat.depthFunc = THREE.GreaterDepth

			@legoBoxHighlightMaterial.transparent = true
			@printBoxHighlightMaterial.transparent = true
			@objectPrintMaterial.transparent = true
			@legoShadowMat.transparent = true

	###
    # Returns the highlight material collection for the supplied type of voxel
    # @param {String} type either 'lego' or '3d' to get the respective material
    ###
	getHighlightMaterial: (type) =>
		if type == 'lego'
			return {
				voxel: @legoHighlightMaterial
				box: @legoBoxHighlightMaterial
			}
		else if type == '3d'
			return {
				voxel: @printHighlightMaterial
				box: @printBoxHighlightMaterial
			}
		return null

	getMaterialForVoxel: (gridEntry) =>
		if gridEntry.enabled
			# if there is a brick at the same position,
			# take the same material
			if gridEntry.brick?.visualizationMaterial?
				return gridEntry.brick.visualizationMaterial
			return @selectedMaterial
		else
			return @hiddenMaterial

	getMaterialForBrick: (brick) =>
		# return stored material or assign a random one
		if brick.visualizationMaterial?
			return brick.visualizationMaterial

		# collect materials of neighbors
		neighbors = brick.getNeighbors()
		neighborColors = []
		neighbors.forEach (neighbor) ->
			neighborColors.push neighbor.visualizationMaterial

		# try max. (brickMaterials.length) times to
		# find a material that has not been used
		# by neighbors to visually distinguish bricks
		for i in [0...@_brickMaterials.length]
			material = @_getRandomBrickMaterial()
			continue if neighborColors.indexOf(material) >= 0
			break

		brick.visualizationMaterial = material
		return brick.visualizationMaterial

	getStabilityMaterialForBrick: (brick) =>
		 @getMaterialForBrick brick

	_getRandomBrickMaterial: =>
		i = Math.floor(Math.random() * @_brickMaterials.length)
		return @_brickMaterials[i]

	_createBrickMaterials: =>
		@_brickMaterials = []
		@_brickMaterials.push @_createMaterial 0x530000
		@_brickMaterials.push @_createMaterial 0xfe2020
		@_brickMaterials.push @_createMaterial 0xba0000
		@_brickMaterials.push @_createMaterial 0xfe5c5c
		@_brickMaterials.push @_createMaterial 0xdb0000
		@_brickMaterials.push @_createMaterial 0x6b0000
		@_brickMaterials.push @_createMaterial 0xfe3939
		@_brickMaterials.push @_createMaterial 0xfe4d4d

	_createMaterial: (color, opacity = 1) ->
		return new THREE.MeshLambertMaterial(
			color: color
			opacity: opacity
			transparent: opacity < 1.0
		)
