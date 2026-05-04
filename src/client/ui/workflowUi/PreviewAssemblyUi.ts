import * as Spinner from "../../Spinner.js"
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
      void this._updateBuildLayer(this.previewUi.sceneManager.selectedNode)
    })

    this.buildLayerUi.increment.on("click", () => {
      this.buildLayerUi.slider.val(Number(this.buildLayerUi.slider.val()) + 1)
      void this._updateBuildLayer(this.previewUi.sceneManager.selectedNode)
    })

    this.buildLayerUi.decrement.on("click", () => {
      this.buildLayerUi.slider.val(Number(this.buildLayerUi.slider.val()) - 1)
      void this._updateBuildLayer(this.previewUi.sceneManager.selectedNode)
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
            return this._updateBuildLayer(selectedNode)
          })
      })
  }

  async _updateBuildLayer (selectedNode: Node | null): Promise<void> {
    const layer = Number(this.buildLayerUi.slider.val())
    this.buildLayerUi.curLayer.text(layer)

    const bundle = this.previewUi.workflowUi.bundle
    const renderArea = document.getElementById(bundle.globalConfig.renderAreaId)
    Spinner.startOverlay(renderArea)
    try {
      // Yield so the browser paints the spinner before the synchronous
      // layer-update work blocks the main thread.
      await new Promise<void>(resolve => setTimeout(resolve, 0))
      await this.previewUi.nodeVisualizer.showBuildLayer(selectedNode, layer)
      await bundle.renderer.render()
    }
    finally {
      Spinner.stop(renderArea)
    }
  }

  _disableBuildMode (selectedNode: Node | null) {
    this.buildContainer.slideUp()
    return this.previewUi.nodeVisualizer.setDisplayMode(selectedNode, this.preBuildMode)
  }
}
