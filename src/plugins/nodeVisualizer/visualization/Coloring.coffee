THREE = require 'three'
LineMatGenerator = require './LineMatGenerator'

# Provides a simple implementation on how to color voxels and bricks
module.exports = class Coloring
	constructor: (@globalConfig) ->
		@textureMaterialCache = {}

		@brickMaterial = new THREE.MeshLambertMaterial({
			color: 0xfff000 #orange
		})

		@studTexture = THREE.ImageUtils.loadTexture('img/stud.png')
		@studTexture.wrapS = THREE.RepeatWrapping
		@studTexture.wrapT = THREE.RepeatWrapping

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
		@printHighlightMaterial.polygonOffset = true
		@printHighlightMaterial.polygonOffsetFactor = -1
		@printHighlightMaterial.polygonOffsetUnits = -1

		@printHighlightTextureMaterial = new THREE.MeshLambertMaterial({
			map: @studTexture
			transparent: true
			opacity: 0.2
		})
		@printHighlightTextureMaterial.polygonOffset = true
		@printHighlightTextureMaterial.polygonOffsetFactor = -1
		@printHighlightTextureMaterial.polygonOffsetUnits = -1

		@legoBoxHighlightMaterial = new THREE.MeshLambertMaterial({
			color: 0xff7755
			opacity: 0.5
			transparent: true
		})
		@legoBoxHighlightMaterial.polygonOffset = true
		@legoBoxHighlightMaterial.polygonOffsetFactor = -1
		@legoBoxHighlightMaterial.polygonOffsetUnits = -1

		@printBoxHighlightMaterial = new THREE.MeshLambertMaterial({
			color: 0xeeeeee
			opacity: 0.4
			transparent: true
		})
		@printBoxHighlightMaterial.polygonOffset = true
		@printBoxHighlightMaterial.polygonOffsetFactor = -1
		@printBoxHighlightMaterial.polygonOffsetUnits = -1

		@csgMaterial = new THREE.MeshLambertMaterial({
			color: 0xb5ffb8 #greenish gray
		})

		@legoShadowMat = new THREE.MeshBasicMaterial({
			color: 0x707070
			transparent: true
			opacity: 0.3
		})
		@legoShadowMat.polygonOffset = true
		@legoShadowMat.polygonOffsetFactor = +2
		@legoShadowMat.polygonOffsetUnits = +2

		# object visualization
		# default object material
		@objectMaterial = new THREE.MeshLambertMaterial(
			color: @globalConfig.colors.modelColor
			ambient: @globalConfig.colors.modelColor
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
			if gridEntry.brick?.visualizationMaterials?
				return gridEntry.brick.visualizationMaterials.color
			return @selectedMaterial
		else
			return @hiddenMaterial

	getMaterialsForBrick: (brick) =>
		# return stored material or assign a random one
		if brick.visualizationMaterials?
			return brick.visualizationMaterials

		# collect materials of neighbors
		neighbors = brick.getNeighborsXY()
		connections = brick.connectedBricks()

		neighborColors = new Set()
		neighbors.forEach (neighbor) ->
			if neighbor.visualizationMaterials?
				neighborColors.add neighbor.visualizationMaterials.color
		connections.forEach (connection) ->
			if connection.visualizationMaterials?
				neighborColors.add connection.visualizationMaterials.color

		# try max. (brickMaterials.length) times to
		# find a material that has not been used
		# by neighbors to visually distinguish bricks
		for i in [0...@_brickMaterials.length]
			materials = @_getRandomBrickMaterials()
			continue if neighborColors.has(materials.color)
			break

		brick.visualizationMaterials = materials
		return brick.visualizationMaterials

	getStabilityMaterialForBrick: (brick) =>
		 @getMaterialForBrick brick

	_getRandomBrickMaterials: =>
		i = Math.floor(Math.random() * @_brickMaterials.length)
		return {color: @_brickMaterials[i], gray: @_grayBrickMaterials[i]}

	_createBrickMaterials: =>
		@_brickMaterials = []
		@_brickMaterials.push @_createMaterial 0x550000
		@_brickMaterials.push @_createMaterial 0x8e0000
		@_brickMaterials.push @_createMaterial 0xc60000
		@_brickMaterials.push @_createMaterial 0xff0000
		@_brickMaterials.push @_createMaterial 0xcc4444
		@_brickMaterials.push @_createMaterial 0xdd4f4f
		@_brickMaterials.push @_createMaterial 0xee5b5b
		@_brickMaterials.push @_createMaterial 0xff6666

		@_grayBrickMaterials = []
		for material in @_brickMaterials
			@_grayBrickMaterials.push @_convertToGrayscale material

	# Clones the material and converts its color to grayscale
	_convertToGrayscale: (material) ->
		newMaterial = material.clone()
		gray = material.color.r * 0.3
		gray += material.color.g * 0.6
		gray += material.color.b * 0.1
		newMaterial.color = new THREE.Color(gray, gray, gray)

		return newMaterial

	_createMaterial: (color, opacity = 1) ->
		return new THREE.MeshLambertMaterial(
			color: color
			opacity: opacity
			transparent: opacity < 1.0
		)

	getTextureMaterialForBrick: (brick) =>
		if brick and brick.getVisualBrick()?
			return brick.getVisualBrick().textureMaterial

		size = if brick then brick.getSize() else {x: 1, y: 1}
		ident = @_getHash size
		if @textureMaterialCache[ident]?
			return @textureMaterialCache[ident]

		studsTexture = @studTexture.clone()
		studsTexture.needsUpdate = true
		studsTexture.repeat.set size.x, size.y

		textureMaterial = new THREE.MeshLambertMaterial({
			map: studsTexture
			transparent: true
			opacity: 0.2
		})

		@textureMaterialCache[ident] = textureMaterial
		return textureMaterial

	_getHash: (dimensions) ->
		return dimensions.x + '-' + dimensions.y
