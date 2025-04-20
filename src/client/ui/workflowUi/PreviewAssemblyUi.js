export default class PreviewAssemblyUi {
  constructor (previewUi) {
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
      return this._updateBuildLayer(this.previewUi.sceneManager.selectedNode)
    })

    this.buildLayerUi.increment.on("click", () => {
      this.buildLayerUi.slider.val(Number(this.buildLayerUi.slider.val()) + 1)
      return this._updateBuildLayer(this.previewUi.sceneManager.selectedNode)
    })

    this.buildLayerUi.decrement.on("click", () => {
      this.buildLayerUi.slider.val(Number(this.buildLayerUi.slider.val()) - 1)
      return this._updateBuildLayer(this.previewUi.sceneManager.selectedNode)
    })
  }

  setEnabled (enabled) {
    if (enabled) {
      return this._enableBuildMode(this.previewUi.sceneManager.selectedNode)
    }
    else {
      return this._disableBuildMode(this.previewUi.sceneManager.selectedNode)
    }
  }

  _enableBuildMode (selectedNode) {
    this.buildContainer.slideDown()

    this.preBuildMode = this.previewUi.nodeVisualizer.getDisplayMode()
    return this.previewUi.nodeVisualizer.setDisplayMode(selectedNode, "build")
      .then(() => {
        return this.previewUi.nodeVisualizer.getNumberOfBuildLayers(selectedNode)
          .then(numLayers => {
            this.buildLayerUi.slider.attr("min", 1)
            this.buildLayerUi.slider.attr("max", numLayers)
            this.buildLayerUi.maxLayer.text(numLayers)

            this.buildLayerUi.slider.val(1)
            return this._updateBuildLayer(selectedNode)
          })
      })
  }

  _updateBuildLayer (selectedNode) {
    const layer = Number(this.buildLayerUi.slider.val())
    this.buildLayerUi.curLayer.text(layer)
    return this.previewUi.nodeVisualizer.showBuildLayer(selectedNode, layer)
  }

  _disableBuildMode (selectedNode) {
    this.buildContainer.slideUp()
    return this.previewUi.nodeVisualizer.setDisplayMode(selectedNode, this.preBuildMode)
  }
}
