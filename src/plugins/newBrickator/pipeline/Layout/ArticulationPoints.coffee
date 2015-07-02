# Finds Articulation Points in a Graph
# Algorithm inspired from
# http://www.geeksforgeeks.org/articulation-points-or-cut-vertices-in-a-graph/
module.exports.findArticulationPoints = (bricks) =>
	articulationPoints = new Set()
	discoveryTime = 0

	bricks.forEach (brick) =>
		return if brick.visited
		dfsWithAP brick, discoveryTime, articulationPoints

	bricks.forEach (brick) =>
		brick.resetArticulationPointData()

	console.log articulationPoints
	return articulationPoints

dfsWithAP = (brick, discoveryTime, articulationPoints) =>
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
			dfsWithAP conBrick, discoveryTime, articulationPoints

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