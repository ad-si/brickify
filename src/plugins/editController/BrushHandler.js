import log from "loglevel"

export default class BrushHandler {
  constructor ( bundle, nodeVisualizer, editController ) {
    this.getBrushes = this.getBrushes.bind(this)
    this._legoSelect = this._legoSelect.bind(this)
    this._printSelect = this._printSelect.bind(this)
    this._applyChanges = this._applyChanges.bind(this)
    this._buildAction = this._buildAction.bind(this)
    this._legoDown = this._legoDown.bind(this)
    this._legoMove = this._legoMove.bind(this)
    this._legoUp = this._legoUp.bind(this)
    this._legoHover = this._legoHover.bind(this)
    this._legoCancel = this._legoCancel.bind(this)
    this._everythingLego = this._everythingLego.bind(this)
    this._printDown = this._printDown.bind(this)
    this._printMove = this._printMove.bind(this)
    this._printUp = this._printUp.bind(this)
    this._printHover = this._printHover.bind(this)
    this._printCancel = this._printCancel.bind(this)
    this._everythingPrint = this._everythingPrint.bind(this)
    this.bundle = bundle
    this.nodeVisualizer = nodeVisualizer
    this.editController = editController
    this.undo = this.bundle.getPlugin("undo")

    this.highlightMaterial = new THREE.MeshLambertMaterial({
      color: 0x00ff00,
    })

    this.legoBrushSelected = false
    this.bigBrushSelected = false

    document.getElementById("everythingLego")
      .addEventListener("click", () => {
        return this._everythingLego(this.nodeVisualizer.selectedNode)
      })

    document.getElementById("everythingPrinted")
      .addEventListener("click", () => {
        return this._everythingPrint(this.nodeVisualizer.selectedNode)
      })
  }

  getBrushes () {
    return [{
      containerId: "#legoBrush",
      onBrushSelect: this._legoSelect,
      onBrushDown: this._legoDown,
      onBrushMove: this._legoMove,
      onBrushOver: this._legoHover,
      onBrushUp: this._legoUp,
      onBrushCancel: this._legoCancel,
    }, {
      containerId: "#printBrush",
      onBrushSelect: this._printSelect,
      onBrushDown: this._printDown,
      onBrushMove: this._printMove,
      onBrushOver: this._printHover,
      onBrushUp: this._printUp,
      onBrushCancel: this._printCancel,
    }]
  }

  _legoSelect (selectedNode, bigBrushSelected) {
    this.bigBrushSelected = bigBrushSelected
    this.legoBrushSelected = true
    if (this.editController.interactionDisabled) {
      return
    }
    return this.nodeVisualizer.setDisplayMode(selectedNode, "legoBrush")
  }

  _printSelect (selectedNode, bigBrushSelected) {
    this.bigBrushSelected = bigBrushSelected
    this.legoBrushSelected = false
    if (this.editController.interactionDisabled) {
      return
    }
    return this.nodeVisualizer.setDisplayMode(selectedNode, "printBrush")
  }

  _applyChanges (touchedVoxels, selectedNode, cachedData) {
    if (!(touchedVoxels.length > 0)) {
      return
    }
    log.debug(`Will re-layout ${touchedVoxels.length} voxel`)

    this.editController.relayoutModifiedParts(
      selectedNode, cachedData, touchedVoxels, true,
    )
    return cachedData.brickVisualization.unhighlightBigBrush()
  }

  _buildAction (touchedVoxels, selectedNode, cachedData) {
    const toLego = () => {
      for (const voxel of Array.from(touchedVoxels)) {
        voxel.makeLego()
        cachedData.brickVisualization.voxelSelector.touch(voxel)
      }
      cachedData.brickVisualization.updateModifiedVoxels()
      return this._applyChanges(touchedVoxels, selectedNode, cachedData)
    }

    const toPrint = () => {
      for (const voxel of Array.from(touchedVoxels)) {
        voxel.make3dPrinted()
        cachedData.brickVisualization.voxelSelector.touch(voxel)
      }
      cachedData.brickVisualization.updateModifiedVoxels()
      return this._applyChanges(touchedVoxels, selectedNode, cachedData)
    }

    return { toLego, toPrint }
  }

  _legoDown (event, selectedNode) {
    return this.nodeVisualizer._getCachedData(selectedNode)
      .then(cachedData => {
        const voxels = cachedData.brickVisualization
          .makeVoxelLego(event, selectedNode, this.bigBrushSelected)
        if (voxels != null) {
          return cachedData.csgNeedsRecalculation = true
        }
      })
  }

  _legoMove (event, selectedNode) {
    return this.nodeVisualizer._getCachedData(selectedNode)
      .then(cachedData => {
        const voxels = cachedData.brickVisualization
          .makeVoxelLego(event, selectedNode, this.bigBrushSelected)
        if (voxels != null) {
          return cachedData.csgNeedsRecalculation = true
        }
      })
  }

  _legoUp (event, selectedNode) {
    return this.nodeVisualizer._getCachedData(selectedNode)
      .then(cachedData => {
        const touchedVoxels = cachedData.brickVisualization.updateModifiedVoxels()

        this._applyChanges(touchedVoxels, selectedNode, cachedData)

        const action = this._buildAction(touchedVoxels, selectedNode, cachedData)
        return this.undo != null ? this.undo.addTask(action.toPrint, action.toLego) : undefined
      })
  }

  _legoHover (event, selectedNode) {
    return this.nodeVisualizer._getCachedData(selectedNode)
      .then(cachedData => {
        return cachedData.brickVisualization
          .highlightVoxel(event, selectedNode, "3d", this.bigBrushSelected)
      })
  }

  _legoCancel (event, selectedNode) {
    return this.nodeVisualizer._getCachedData(selectedNode)
      .then((cachedData) => {
        cachedData.brickVisualization.resetTouchedVoxelsTo3dPrinted()
        cachedData.brickVisualization.updateVisualization()
        return cachedData.brickVisualization.unhighlightBigBrush()
      })
  }

  _everythingLego (node) {
    return this.nodeVisualizer._getCachedData(node)
      .then(cachedData => {
        let apply
        const changedVoxels = cachedData.brickVisualization.makeAllVoxelsLego(node)
        if (changedVoxels.length === 0) {
          return
        }
        (apply = () => {
          this.editController.rerunLegoPipeline(node)
          const brickVis = cachedData.brickVisualization
          brickVis.updateModifiedVoxels()
          return brickVis.updateVisualization(null, true)
        })()

        const action = this._buildAction(changedVoxels, node, cachedData)
        const redo = () => {
          cachedData.brickVisualization.makeAllVoxelsLego(node)
          return apply()
        }
        return this.undo != null ? this.undo.addTask(action.toPrint, redo) : undefined
      })
  }


  _printDown (event, selectedNode) {
    return this.nodeVisualizer._getCachedData(selectedNode)
      .then(cachedData => {
        const voxels = cachedData.brickVisualization
          .makeVoxel3dPrinted(event, selectedNode, this.bigBrushSelected)
        if (voxels != null) {
          return cachedData.csgNeedsRecalculation = true
        }
      })
  }

  _printMove (event, selectedNode) {
    return this.nodeVisualizer._getCachedData(selectedNode)
      .then(cachedData => {
        const voxels = cachedData.brickVisualization
          .makeVoxel3dPrinted(event, selectedNode, this.bigBrushSelected)
        if (voxels != null) {
          return cachedData.csgNeedsRecalculation = true
        }
      })
  }

  _printUp (event, selectedNode) {
    return this.nodeVisualizer._getCachedData(selectedNode)
      .then(cachedData => {
        const touchedVoxels = cachedData.brickVisualization.updateModifiedVoxels()

        this._applyChanges(touchedVoxels, selectedNode, cachedData)

        const action = this._buildAction(touchedVoxels, selectedNode, cachedData)
        return this.undo != null ? this.undo.addTask(action.toLego, action.toPrint) : undefined
      })
  }

  _printHover (event, selectedNode) {
    return this.nodeVisualizer._getCachedData(selectedNode)
      .then(cachedData => {
        return cachedData.brickVisualization
          .highlightVoxel(event, selectedNode, "lego", this.bigBrushSelected)
      })
  }

  _printCancel (event, selectedNode) {
    return this.nodeVisualizer._getCachedData(selectedNode)
      .then((cachedData) => {
        cachedData.brickVisualization.resetTouchedVoxelsToLego()
        cachedData.brickVisualization.updateVisualization()
        return cachedData.brickVisualization.unhighlightBigBrush()
      })
  }

  _everythingPrint (node) {
    return this.nodeVisualizer._getCachedData(node)
      .then(cachedData => {
        const changedVoxels = cachedData.brickVisualization.makeAllVoxels3dPrinted(node)
        if (changedVoxels.length === 0) {
          return
        }
        cachedData.brickVisualization.updateModifiedVoxels()
        this.editController.relayoutModifiedParts(
          node, cachedData, changedVoxels, true,
        )

        const action = this._buildAction(changedVoxels, node, cachedData)
        return this.undo != null ? this.undo.addTask(action.toLego, action.toPrint) : undefined
      })
  }
}
