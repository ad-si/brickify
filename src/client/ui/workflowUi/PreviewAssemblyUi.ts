import type PreviewUi from "./PreviewUi.js"
import type Node from "../../../common/project/node.js"

interface BuildLayerUi {
  slider: JQuery
  decrement: JQuery
  increment: JQuery
  curLayer: JQuery
  maxLayer: JQuery
}

export default class PreviewAssemblyUi {
  previewUi: PreviewUi
  buildContainer: JQuery
  buildLayerUi: BuildLayerUi
  preBuildMode!: string

  constructor (previewUi: PreviewUi) {
    this.setEnabled = this.setEnabled.bind(this)
    this._enableBuildMode = this._enableBuildMode.bind(this)
    this._updateBuildLayer = this._updateBuildLayer.bind(this)
    this._disableBuildMode = this._disableBuildMode.bind(this)
    this.previewUi = previewUi
    this.buildContainer = $("#buildContainer")
    this.buildContainer.hide()
    this.buildContainer.removeClass("hidden")

    this.buildLayerUi = {
      slider: $("#buildSlider"),
      decrement: $("#buildDecrement"),
      increment: $("#buildIncrement"),
      curLayer: $("#currentBuildLayer"),
      maxLayer: $("#maxBuildLayer"),
    }

    this.buildLayerUi.slider.on("input", () => {
      this._updateBuildLayer(this.previewUi.sceneManager.selectedNode)
    })

    this.buildLayerUi.increment.on("click", () => {
      this.buildLayerUi.slider.val(Number(this.buildLayerUi.slider.val()) + 1)
      this._updateBuildLayer(this.previewUi.sceneManager.selectedNode)
    })

    this.buildLayerUi.decrement.on("click", () => {
      this.buildLayerUi.slider.val(Number(this.buildLayerUi.slider.val()) - 1)
      this._updateBuildLayer(this.previewUi.sceneManager.selectedNode)
    })
  }

  setEnabled (enabled: boolean) {
    if (enabled) {
      return this._enableBuildMode(this.previewUi.sceneManager.selectedNode)
    }
    else {
      return this._disableBuildMode(this.previewUi.sceneManager.selectedNode)
    }
  }

  _enableBuildMode (selectedNode: Node | null) {
    this.buildContainer.slideDown()

    this.preBuildMode = this.previewUi.nodeVisualizer.getDisplayMode()
    return this.previewUi.nodeVisualizer.setDisplayMode(selectedNode, "build")
      .then(() => {
        return this.previewUi.nodeVisualizer.getNumberOfBuildLayers(selectedNode)
          .then((numLayers: number) => {
            this.buildLayerUi.slider.attr("min", 1)
            this.buildLayerUi.slider.attr("max", numLayers)
            this.buildLayerUi.maxLayer.text(numLayers)

            this.buildLayerUi.slider.val(1)
            this._updateBuildLayer(selectedNode)
          })
      })
  }

  _updateBuildLayer (selectedNode: Node | null) {
    const layer = Number(this.buildLayerUi.slider.val())
    this.buildLayerUi.curLayer.text(layer)
    this.previewUi.nodeVisualizer.showBuildLayer(selectedNode, layer)
  }

  _disableBuildMode (selectedNode: Node | null) {
    this.buildContainer.slideUp()
    return this.previewUi.nodeVisualizer.setDisplayMode(selectedNode, this.preBuildMode)
  }
}
