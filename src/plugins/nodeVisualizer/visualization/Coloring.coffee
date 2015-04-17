THREE = require 'three'

# Provides a simple implementation on how to color voxels and bricks
module.exports = class Coloring
	constructor: ->
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

		@_createBrickMaterials()
		@_createThreeLayerBrickMaterials()

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
			if brick.getSize().z == 1
				material = @_getRandomBrickMaterial()
			else if brick.getSize().z == 3
				material = @_getRandomThreeLayerBrickMaterial()
			else
				material = @_createMaterial 0xffffff
				console.log brick
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

	_getRandomThreeLayerBrickMaterial: =>
		i = Math.floor(Math.random() * @_tlBrickMaterials.length)
		return @_tlBrickMaterials[i]

	_createThreeLayerBrickMaterials: =>
		@_tlBrickMaterials = []
		@_tlBrickMaterials.push @_createMaterial 0x0000ff
		@_tlBrickMaterials.push @_createMaterial 0x000066
		@_tlBrickMaterials.push @_createMaterial 0x00ffff
		@_tlBrickMaterials.push @_createMaterial 0x0099ff
		@_tlBrickMaterials.push @_createMaterial 0x333399
		@_tlBrickMaterials.push @_createMaterial 0x663366

	_createMaterial: (color, opacity = 1) ->
		return new THREE.MeshLambertMaterial(
			color: color
			opacity: opacity
			transparent: opacity < 1.0
		)
