log = require 'loglevel'

Brick = require '../Brick'
Voxel = require '../Voxel'
DataHelper = require '../DataHelper'
Random = require '../Random'


class LayoutOptimizer
	constructor: (@brickLayouter, @plateLayouter,
								pseudoRandom = false) ->
		Random.usePseudoRandom pseudoRandom

	optimizeLayoutStability: (grid) =>
		maxNumPasses = 15

		for pass in [0...maxNumPasses]
			bricks = grid.getAllBricks()
			log.debug '\t# of bricks: ', bricks.size

			bricks.forEach (brick) ->
				brick.label = null

			numberOfComponents = @_findConnectedComponents bricks
			log.debug '\t# of components: ', numberOfComponents

			bricksToSplit = @_bricksOnComponentInterfaces bricks
			log.debug '\t# of bricks to split: ', bricksToSplit.size

			if bricksToSplit.size is 0
				break
			else
				@splitBricksAndRelayoutLocally bricksToSplit, grid, false, false

		log.debug '\tfinished optimization after ', pass , 'passes'

		@_findArticulationPoints bricks

		return Promise.resolve grid

	# Connected components using the connected component labelling algo
	_findConnectedComponents: (bricks) =>
		labels = []
		id = 0

		# First pass
		bricks.forEach (brick) ->
			conBricks = brick.connectedBricks()
			conLabels = new Set()

			conBricks.forEach (conBrick) ->
				conLabels.add conBrick.label if conBrick.label?

			if conLabels.size > 0
				smallestLabel = DataHelper.smallestElement conLabels
				# Assign label to this brick
				brick.label = labels[smallestLabel]
				for i in [0..labels.length]
					if conLabels.has labels[i]
						labels[i] = labels[smallestLabel]

			else # No neighbor has a label
				brick.label = id
				labels[id] = id

				id++

		# Second pass - applying labels
		bricks.forEach (brick) ->
			brick.label = labels[brick.label]

		# Count number of components
		finalLabels = new Set()
		for label in labels
			finalLabels.add label
		numberOfComponents = finalLabels.size

		return numberOfComponents

	_bricksOnComponentInterfaces: (bricks) =>
		bricksOnInterfaces = new Set()

		bricks.forEach (brick) ->
			neighborsXY = brick.getNeighborsXY()
			neighborsXY.forEach (neighbor) ->
				if neighbor.label != brick.label
					bricksOnInterfaces.add neighbor
					bricksOnInterfaces.add brick

		return bricksOnInterfaces

	# Finds Articulation Points in a Graph
	# Algorithm inspired from
	# http://www.geeksforgeeks.org/articulation-points-or-cut-vertices-in-a-graph/
	_findArticulationPoints: (bricks) =>
		articulationPoints = new Set()
		discoveryTime = 0

		bricks.forEach (brick) =>
			return if brick.visited
			@_dfsWithAP brick, discoveryTime, articulationPoints

		bricks.forEach (brick) =>
			brick.resetArticulationPointData()

		console.log articulationPoints
		return articulationPoints

	_dfsWithAP: (brick, discoveryTime, articulationPoints) =>
		# Mark the current node as visited
		brick.visited = true

		# Initialize discovery time and low value
		++discoveryTime
		brick.discoveryTime = discoveryTime
		brick.low = discoveryTime

		connectedBricks = brick.connectedBricks()
		connectedBricks.forEach (conBrick) =>
			if not conBrick.visited
				brick.children++
				conBrick.parent = brick
				@_dfsWithAP conBrick, discoveryTime, articulationPoints

				# Check if the subtree rooted with v has a connection to
				# one of the ancestors of u
				brick.low  = Math.min brick.low, conBrick.low

				# brick is an articulation point in following cases

				# (1) brick is root of DFS tree and has two or more children
				if (brick.parent is null and brick.children > 1)
					articulationPoints.add brick

				# (2) If u is not root and low value of one of its child is more
				# than discovery value of u
				if (brick.parent isnt null and conBrick.low >= brick.discoveryTime)
					articulationPoints.add brick

			# Update low value of u for parent function calls
			else if conBrick isnt brick.parent
				brick.low = Math.min brick.low, conBrick.discoveryTime



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
