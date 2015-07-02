log = require 'loglevel'

Brick = require '../Brick'
Voxel = require '../Voxel'
Random = require '../Random'
ConComp = require './ConnectedComponents'
AP = require './ArticulationPoints'


class LayoutOptimizer
	constructor: (@brickLayouter, @plateLayouter,
								pseudoRandom = false) ->
		Random.usePseudoRandom pseudoRandom

	optimizeLayoutStability: (grid) =>
		maxNumPasses = 15

		for pass in [0...maxNumPasses]
			bricks = grid.getAllBricks()
			log.debug '\t# of bricks: ', bricks.size

			# Connected Components
			bricks.forEach (brick) -> brick.label = null
			numberOfComponents = ConComp.findConnectedComponents bricks
			log.debug '\t# of components: ', numberOfComponents
			bricksToSplit = ConComp.bricksOnComponentInterfaces bricks
			log.debug '\t# of bricks to split: ', bricksToSplit.size

			if bricksToSplit.size is 0
				break
			else
				@splitBricksAndRelayoutLocally bricksToSplit, grid, false, false

			# Articulation Points
			bricks.forEach (brick) =>
				brick.resetArticulationPointData()
			articulationPoints = AP.findArticulationPoints bricks
			console.log articulationPoints


		log.debug '\tfinished optimization after ', pass , 'passes'
		return Promise.resolve grid

	###
	# Split up all supplied bricks into single bricks and relayout locally. This
	# means that all supplied bricks and (optionally) their neighbors
	# will be relayouted.
	#
	# @param {Set<Brick>} bricks bricks that should be split
	# @param {Grid} grid the grid the bricks belong to
	# @param {Boolean} [splitNeighbors=true ] whether or not neighbors will be
	# split up and relayouted
	# @param {Boolean} [useThreeLayers=true] whether BrickLayouter should be used
	# first before PlateLayouter
	###
	splitBricksAndRelayoutLocally: (bricks, grid,
																	splitNeighbors = true, useThreeLayers = true) =>
		bricksToSplit = new Set()

		bricks.forEach (brick) ->
			# add this brick to be split
			bricksToSplit.add brick


			if splitNeighbors
				# Get neighbors in same z layer
				neighbors = brick.getNeighborsXY()
				# Add them all to be split as well
				neighbors.forEach (nBrick) -> bricksToSplit.add nBrick

		newBricks = @_splitBricks bricksToSplit

		bricksToBeDeleted = new Set()

		newBricks.forEach (brick) ->
			brick.forEachVoxel (voxel) ->
				# Delete bricks where voxels are disabled (3d printed)
				if not voxel.enabled
					# Remove from relayout list
					bricksToBeDeleted.add brick
					# Delete brick from structure
					brick.clear()

		bricksToBeDeleted.forEach (brick) ->
			newBricks.delete brick

		if useThreeLayers
			@brickLayouter.layout grid, newBricks
		@plateLayouter.layout grid, newBricks
		.then ->
			return {
				removedBricks: bricksToSplit
				newBricks: newBricks
			}

	# Splits each brick in bricks to split, returns all newly generated
	# bricks as a set
	_splitBricks: (bricksToSplit) ->
		newBricks = new Set()

		bricksToSplit.forEach (brick) ->
			splitGenerated = brick.splitUp()
			splitGenerated.forEach (brick) ->
				newBricks.add brick

		return newBricks

module.exports = LayoutOptimizer
