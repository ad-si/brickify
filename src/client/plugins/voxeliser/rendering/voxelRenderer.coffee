module.exports = (voxelisedModel) ->
	geometry = makeGeometry voxelisedModel.bricksystem
	node = new THREE.Object3D()
	for brickSpace in voxelisedModel.outer_Bricks
		node.add makeBrick brickSpace, geometry, voxelisedModel
	node

makeGeometry = (bricksystem) ->
	new THREE.BoxGeometry bricksystem.width, bricksystem.depth, bricksystem.height

makeBrick = (brickSpace, geometry, voxelisedModel) ->
	mesh = new THREE.Mesh geometry
	bricksystem = voxelisedModel.bricksystem
	position = voxelisedModel.position
	mesh.position.set(
		(brickSpace.x + 0.5) * bricksystem.width + position.x
		(brickSpace.y + 0.5) * bricksystem.depth + position.y
		(brickSpace.z + 0.5) * bricksystem.height + position.z
	)
	mesh
