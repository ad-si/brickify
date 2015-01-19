THREE = require 'three'

module.exports = class BrickVisualizer
  constructor: () ->
    @basicMaterial = new THREE.MeshLambertMaterial({
      color: 0x48b427 #green
      opacity: 1
      transparent: true
    })
    return

  createBricks: () ->
    return

  createBrick: (grid, threeNode, drawInnerBricks = true) =>

    ###
    # material

    @brickGeometry = new THREE.BoxGeometry(
      grid.spacing.x, grid.spacing.y, grid.spacing.z )

    cube = new THREE.Mesh( @voxelGeometry, m )
    cube.translateX( grid.origin.x + grid.spacing.x * x)
    cube.translateY( grid.origin.y + grid.spacing.y * y)
    cube.translateZ( grid.origin.z + grid.spacing.z * z)

    cube.brickCoords  = {
      x: x
      y: y
      z: z
    }

    threeNode.add(cube)

  ###