import { PNG } from "node-png"
import THREE from "three"
import log from "loglevel"

import threeHelper from "../../client/threeHelper.js"
import pieceListGenerator from "./PieceListGenerator.js"
import openScadGenerator from "./OpenScadGenerator.js"


export default class LegoInstructions {
  constructor () {
    this.getDownload = this.getDownload.bind(this)
    this.showPartListPopup = this.showPartListPopup.bind(this)
    this._takeScreenshots = this._takeScreenshots.bind(this)
    this._createScreenshotOfLayer = this._createScreenshotOfLayer.bind(this)
    this._flipAndFitImage = this._flipAndFitImage.bind(this)
    this._createHtml = this._createHtml.bind(this)
    this._downloadPieceListImages = this._downloadPieceListImages.bind(this)
  }

  init (bundle) {
    this.renderer = bundle.renderer
    this.nodeVisualizer = bundle.getPlugin("nodeVisualizer")
    this.newBrickator = bundle.getPlugin("newBrickator")
    this.fidelityControl = bundle.getPlugin("fidelity-control")
    return this.imageResolution = bundle.globalConfig.legoInstructionResolution
  }

  getDownload (node, downloadOptions) {
    if (downloadOptions.type !== "instructions") {
      return null
    }

    log.debug("Creating instructions...")

    // pseudoisometric
    const camera = new THREE.PerspectiveCamera(
      this.renderer.camera.fov, this.renderer.camera.aspect, 1, 1000,
    )

    camera.position.set(1, 1, 1)
    camera.lookAt(new THREE.Vector3(0, 0, 0))
    camera.up = new THREE.Vector3(0, 0, 1)

    const oldVisualizationMode = this.nodeVisualizer.getDisplayMode()

    return this.nodeVisualizer.getBrickThreeNode(node)
      .then(brickNode => {
        threeHelper.zoomToBoundingSphere(
          camera,
          this.renderer.scene,
          null,
          threeHelper.getBoundingSphere(brickNode),
        )
        // disable pipeline and fidelity changes
        this.fidelityControl.enableScreenshotMode()
        // enter build mode
        return this.nodeVisualizer.setDisplayMode(node, "build")
      })
      .then(() => this.newBrickator.getNodeData(node))
      .then(data => {
        return this.nodeVisualizer.getNumberOfBuildLayers(node)
          .then(numLayers => {
            // scad and piece list generation
            const bricks = data.grid.getAllBricks()
            if (bricks.size === 0) {
              return null
            }

            const files = []
            files.push(openScadGenerator.generateScad(bricks))

            // add instructions html to download
            const pieceList = pieceListGenerator.generatePieceList(bricks)
            files.push(this._createHtml(numLayers, pieceList))

            // Take screenshots and convert them to png
            const screenshots = this._takeScreenshots(node, numLayers, camera)
              .then((images) => {
                files.push(...Array.from(images || []))
                return log.debug("Finished instruction screenshots")
              })

            // Load and save piece images
            const imageDownload = this._downloadPieceListImages(pieceList)
              .then(imageFiles => files.push(...Array.from(imageFiles || [])))

            return Promise.all([screenshots, imageDownload])
              .then(() => files)
          })
      })
      .then(files => {
        // reset display mode
        this.nodeVisualizer.setDisplayMode(node, oldVisualizationMode)
        this.fidelityControl.disableScreenshotMode()

        return files
      })
      .catch((error) => {
        log.error(error)
        return null
      })
  }

  showPartListPopup (node) {
    return this.newBrickator.getNodeData(node)
      .then(data => {
        const bricks = data.grid.getAllBricks()
        const pieceList = pieceListGenerator.generatePieceList(bricks)
        const pieceListHtml = pieceListGenerator.getHtml(pieceList, false)

        return bootbox.dialog({
          title: "Parts needed",
          message: pieceListHtml,
          backdrop: true,
        })
      })
  }

  _takeScreenshots (node, numLayers, camera) {
    const files = []
    const takeScreenshot = layer => () => {
      return this._createScreenshotOfLayer(node, layer, camera)
        .then(fileData => files.push({
          fileName: fileData.fileName,
          data: fileData.data,
        }))
    }

    // screenshot of each layer
    let promiseChain = Promise.resolve()
    for (let layer = 1, end = numLayers, asc = end >= 1; asc ? layer <= end : layer >= end; asc ? layer++ : layer--) {
      promiseChain = promiseChain.then(takeScreenshot(layer))
    }

    return promiseChain.then(() => files)
  }

  _createScreenshotOfLayer (node, layer, camera) {
    return this.nodeVisualizer.showBuildLayer(node, layer)
      .then(() => {
        log.debug("Create screenshot of layer", layer)
        return this.renderer.renderToImage(camera, this.imageResolution)
      })
      .then(pixelData => {
        const flippedImage = this._flipAndFitImage(pixelData)
        return this._convertToPng(flippedImage)
          .then(pngData => ({
            fileName: `img/instructions/layer-${layer}.png`,
            data: pngData.buffer,
            imageWidth: flippedImage.width,
          }))
      })
  }

  _convertToPng (image) {
    return new Promise((resolve, reject) => {
      const png = new PNG({
        width: image.width,
        height: image.height,
      })
      for (let i = 0, end = image.data.length, asc = end >= 0; asc ? i < end : i > end; asc ? i++ : i--) {
        png.data[i] = image.data[i]
      }
      png.pack()

      let pngData = new Uint8Array(0)

      // read png stream
      png.on("data", (data) => {
        const newData = new Uint8Array(pngData.length + data.length)
        newData.set(pngData)
        newData.set(data, pngData.length)
        return pngData = newData
      })
      return png.on("end", () => resolve(pngData))
    })
  }

  // flips the image vertically (because renderer delivers it upside down)
  // and scales it to actual recorded screen measurements (because it is always
  // in size 2^n)
  _flipAndFitImage (renderedImage) {
    let sw = renderedImage.viewWidth
    let sh = renderedImage.viewHeight
    const iw = renderedImage.imageWidth
    const ih = renderedImage.imageHeight

    // scale screen to match image dimensions,
    // but retain aspect ratio
    const biggerView = Math.max(sw, sh)
    const biggerImage = Math.max(iw, ih)

    const scaleFactor = biggerImage / biggerView

    sw = Math.round(sw * scaleFactor)
    sh = Math.round(sh * scaleFactor)

    // create new image
    const newImage = new Uint8Array(sw * sh * 4)

    const scaleX = iw / sw
    const scaleY = ih / sh

    for (let y = 0, end = sh, asc = end >= 0; asc ? y < end : y > end; asc ? y++ : y--) {
      // flip new y coordinates
      const newY = (sh - 1) - y
      const oldY = Math.round(y * scaleY)

      for (let x = 0, end1 = sw, asc1 = end1 >= 0; asc1 ? x < end1 : x > end1; asc1 ? x++ : x--) {
        const newX = x
        const oldX = Math.round(x * scaleX)

        const pixelData = this._getPixel(renderedImage.pixels, iw, oldX, oldY)
        this._setPixel(newImage, sw, newX, newY, pixelData)
      }
    }

    return {
      data: newImage,
      width: sw,
      height: sh,
    }
  }

  _getPixel (imageData, imageWidth, x, y) {
    let index = (imageWidth * y) + x
    index *= 4
    return [
      imageData[index],
      imageData[index + 1],
      imageData[index + 2],
      imageData[index + 3],
    ]
  }

  _setPixel (imageData, imageWidth, x, y, ...rest) {
    const [r, g, b, a] = Array.from(rest[0])
    let index = (imageWidth * y) + x
    index *= 4
    imageData[index] = r
    imageData[index + 1] = g
    imageData[index + 2] = b
    return imageData[index + 3] = a
  }

  _createHtml (numLayers, pieceList) {
    const pieceListHtml = pieceListGenerator.getHtml(pieceList)

    const style = "<style> \
img{max-width: 100%;} \
h1,h3,p,td{font-family:Helvetica, Arial, sans-serif;} \
td{min-width: 80px;} \
.pageBreak{page-break-before: always;} \
</style>"

    let html = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \
\"http://www.w3.org/TR/html4/strict.dtd\">"
    html += "<html><head> \
<title>LEGO assembly instructions</title> \
</head><body><h1>Build instructions</h1>"

    html += style

    html += pieceListHtml

    for (let i = 1, end = numLayers, asc = end >= 1; asc ? i <= end : i >= end; asc ? i++ : i--) {
      html += "<br><br>"
      html += '<h3 class="pageBreak"> Layer ' + i + "</h3>"
      html += '<p><img src="img/instructions/layer-' + i + '.png"></p>'
    }

    html += "</body></html>"

    return {
      fileName: "LEGO_Assembly_instructions.html",
      data: html,
    }
  }

  _downloadPieceListImages (pieceList) {
    return Promise.all(pieceList.map(piece => this._downloadPieceImage(piece)))
  }

  _downloadPieceImage (piece) {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest()
      const fileName = `img/partList/partList-${piece.sizeIndex + 1}.png`
      xhr.open("GET", fileName)
      xhr.responseType = "arraybuffer"
      xhr.onload = function (event) {
        return resolve({
          fileName,
          // as requested, response is an ArrayBuffer
          data: this.response,
        })
      }
      xhr.onerror = reject
      xhr.onabort = reject
      xhr.ontimeout = reject
      return xhr.send()
    })
  }
}
