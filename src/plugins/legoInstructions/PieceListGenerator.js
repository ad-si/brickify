import log from "loglevel"

import Brick from "../newBrickator/pipeline/Brick.js"


// generates a list of how many bricks of which size
// is in the given set of bricks
export function generatePieceList (bricks) {
  const pieceList = []

  bricks.forEach((brick) => {
    let brickType
    for (brickType of Array.from(pieceList)) {
      if (Brick.isSizeEqual(brickType.size, brick.getSize())) {
        brickType.count++
        return
      }
    }

    const size = brick.getSize()
    brickType = {
      size: {
        x: Math.min(size.x, size.y),
        y: Math.max(size.x, size.y),
        z: size.z,
      },
      count: 1,
    }
    brickType.sizeIndex = Brick.getSizeIndex(brickType.size)
    return pieceList.push(brickType)
  })

  // sort bricks from small to big
  pieceList.sort((a, b) => {
    if (a.size.x === b.size.x) {
      return a.size.y - b.size.y
    }
    else {
      return a.size.x - b.size.x
    }
  })

  return pieceList
}


export function getHtml (list, caption) {
  if (caption == null) {
    caption = true
  }
  let html = ""

  if (caption) {
    html = "<h3>Bricks needed</h3>"
  }

  html +=
    "<p>To build this model you need the following bricks:" +
    '<style type="text/css">' +
    ".partListTable td{vertical-align:middle !important;}" +
    "</style>" +
    '<table class="table partListTable">' +
    "<tr><th>Size</th>" +
    "<th>Type</th>" +
    "<th>Amount</th>" +
    "<th>Image</th></tr>"

  for (const piece of Array.from(list)) {
    var type
    if (piece.size.z === 1) {
      type = "Plate"
    }
    else if (piece.size.z === 3) {
      type = "Brick"
    }
    else {
      log.warn("Invalid LEGO height for piece list")
      continue
    }

    html +=
      "<tr>" +
      `<td>${piece.size.x} x ${piece.size.y}</td>` +
      `<td>${type}</td>` +
      `<td>${piece.count}x</td>` +
      '<td><img src="img/partList/partList-' + (piece.sizeIndex + 1) +
      '.png" height="40px"></td>' +
      "</tr>"
  }

  html += "</table></p>"
  return html
}
