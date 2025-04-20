import _scadBase from "./brick.scad"

const toScadVector = vector => `[${vector.x}, ${vector.y}, ${vector.z}]`

module.exports.generateScad = function (bricks) {
  let scad = _scadDisclaimer()

  bricks.forEach((brick) => {
    const pos = toScadVector(brick.getPosition())
    const size = toScadVector(brick.getSize())
    return scad += `GridTranslate(${pos}){ Brick(${size}); }\n`
  })

  scad += "\n\n"
  scad += _scadBase

  return {
    fileName: "bricks.scad",
    data: scad,
  }
}

var _scadDisclaimer = () => "\
/*\n \
* \n \
* Brick layout for openSCAD\n \
* Generated with http://brickify.it\n \
*\n \
*/\n\n\
"
