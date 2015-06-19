THREE = require 'three'
LineMatGenerator = require './LineMatGenerator'

# Provides a simple implementation on how to color voxels and bricks
module.exports = class Coloring
	constructor: (@globalConfig) ->
		@textureMaterialCache = {}

		@brickMaterial = @_createMaterial 0xfff000 #orange

		@studTexture = THREE.ImageUtils.loadTexture('img/stud.png')
		@studTexture.wrapS = THREE.RepeatWrapping
		@studTexture.wrapT = THREE.RepeatWrapping

		@selectedMaterial = @_createMaterial 0xff0000

		@hiddenMaterial = @_createMaterial 0xffaaaa, 0.0

		@legoHighlightMaterial = @_createMaterial 0xff7755

		@printHighlightMaterial = @_createMaterial 0xeeeeee
		@_setPolygonOffset @printHighlightMaterial, -1, -1

		@printHighlightTextureMaterial = @_createMaterial 0xffffff, 0.2
		@printHighlightTextureMaterial.map = @studTexture
		@_setPolygonOffset @printHighlightTextureMaterial, -1, -1

		@legoBoxHighlightMaterial = @_createMaterial 0xff7755, 0.5
		@_setPolygonOffset @legoBoxHighlightMaterial, -1, -1

		@printBoxHighlightMaterial = @_createMaterial 0xeeeeee, 0.4
		@_setPolygonOffset @printBoxHighlightMaterial, -1, -1

		@csgMaterial = @_createMaterial 0xb5ffb8 #greenish gray

		@legoShadowMat = new THREE.MeshBasicMaterial({
			color: 0x707070
			transparent: true
			opacity: 0.3
		})
		@_setPolygonOffset @legoShadowMat, +2, +2

		# printed object material
		@objectPrintMaterial = @_createMaterial @globalConfig.colors.modelColor, 0.8

		# remove z-Fighting on baseplate
		@_setPolygonOffset @objectPrintMaterial, +3, +3

		@objectShadowMat = new THREE.MeshBasicMaterial(
			color: 0x000000
			transparent: true
			opacity: 0.4
			depthFunc: THREE.GreaterDepth
		)
		@_setPolygonOffset @objectShadowMat, +3, +3

		lineMaterialGenerator = new LineMatGenerator()
		@objectLineMat = lineMaterialGenerator.generate 0x000000
		@objectLineMat.linewidth = 2
		@objectLineMat.transparent = true
		@objectLineMat.opacity = 0.1
		@objectLineMat.depthFunc = THREE.GreaterDepth
		@objectLineMat.depthWrite = false

		@_createBrickMaterials()

	_setPolygonOffset: (material, polygonOffsetFactor, polygonOffsetUnits) ->
		material.polygonOffset = true
		material.polygonOffsetFactor = polygonOffsetFactor
		material.polygonOffsetUnits = polygonOffsetUnits

	setPipelineMode: (enabled) =>
		@objectPrintMaterial.transparent = !enabled

		@objectShadowMat.visible = !enabled
		@objectLineMat.transparent = !enabled
		@objectLineMat.depthWrite = enabled
		if enabled
			@objectLineMat.depthFunc = THREE.LessEqualDepth
		else
			@objectLineMat.depthFunc = THREE.GreaterDepth

		@legoBoxHighlightMaterial.transparent = !enabled
		@printBoxHighlightMaterial.transparent = !enabled
		@objectPrintMaterial.transparent = !enabled
		@legoShadowMat.transparent = !enabled

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
		colorList = [
			0x550000
			0x8e0000
			0xc60000
			0xff0000
			0xcc4444
			0xdd4f4f
			0xee5b5b
			0xff6666
		]
		@_brickMaterials = []
		for color in colorList
			@_brickMaterials.push @_createMaterial color

		@_grayBrickMaterials = []
		for material in @_brickMaterials
			@_grayBrickMaterials.push @_convertToGrayscale material

	# Clones the material and converts its color to grayscale
	_convertToGrayscale: (material) ->
		newMaterial = material.clone()
		gray = material.color.r * 0.3
		gray += material.color.g * 0.6
		gray += material.color.b * 0.1
		newMaterial.color.setRGB gray, gray, gray

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

		textureMaterial = new THREE.MeshLambertMaterial(
			map: studsTexture
			transparent: true
			opacity: 0.2
		)

		@textureMaterialCache[ident] = textureMaterial
		return textureMaterial

	_getHash: (dimensions) ->
		return dimensions.x + '-' + dimensions.y
