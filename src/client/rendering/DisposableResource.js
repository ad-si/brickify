import log from "loglevel"

export default class DisposableResource {
  constructor() {
    this.disposed = false
    this.disposables = new Set()
    this.childDisposables = new Set()
  }

  track(resource) {
    if (!resource) return resource
    
    if (this.disposed) {
      log.warn('Attempting to track resource on already disposed object')
      this.disposeResource(resource)
      return resource
    }

    this.disposables.add(resource)
    return resource
  }

  trackChild(childDisposable) {
    if (!childDisposable || typeof childDisposable.dispose !== 'function') {
      log.warn('Attempting to track non-disposable child')
      return childDisposable
    }
    
    this.childDisposables.add(childDisposable)
    return childDisposable
  }

  untrack(resource) {
    this.disposables.delete(resource)
  }

  dispose() {
    if (this.disposed) {
      log.warn('Attempting to dispose already disposed resource')
      return
    }

    this.disposed = true

    // Dispose all child disposables first
    for (const child of this.childDisposables) {
      try {
        if (child && typeof child.dispose === 'function') {
          child.dispose()
        }
      } catch (error) {
        log.error('Error disposing child resource:', error)
      }
    }
    this.childDisposables.clear()

    // Dispose tracked Three.js resources
    for (const resource of this.disposables) {
      this.disposeResource(resource)
    }
    this.disposables.clear()

    // Call custom cleanup if implemented
    if (typeof this.onDispose === 'function') {
      try {
        this.onDispose()
      } catch (error) {
        log.error('Error in custom dispose method:', error)
      }
    }
  }

  disposeResource(resource) {
    if (!resource) return

    try {
      // Handle Three.js geometries
      if (resource.geometry) {
        if (typeof resource.geometry.dispose === 'function') {
          resource.geometry.dispose()
        }
      }

      // Handle Three.js materials
      if (resource.material) {
        this.disposeMaterial(resource.material)
      }

      // Handle Three.js textures
      if (resource.texture && typeof resource.texture.dispose === 'function') {
        resource.texture.dispose()
      }

      // Handle render targets
      if (resource.renderTarget && typeof resource.renderTarget.dispose === 'function') {
        resource.renderTarget.dispose()
      }

      // Handle objects with direct dispose method
      if (typeof resource.dispose === 'function') {
        resource.dispose()
      }

      // Handle Three.js Object3D (remove from parent)
      if (resource.parent && typeof resource.parent.remove === 'function') {
        resource.parent.remove(resource)
      }

    } catch (error) {
      log.error('Error disposing Three.js resource:', error, resource)
    }
  }

  disposeMaterial(material) {
    if (!material) return

    try {
      if (Array.isArray(material)) {
        // Handle material arrays
        for (const mat of material) {
          this.disposeMaterial(mat)
        }
      } else {
        // Dispose material textures first
        const textureProperties = ['map', 'lightMap', 'bumpMap', 'normalMap', 
                                  'specularMap', 'envMap', 'alphaMap', 'aoMap', 
                                  'displacementMap', 'roughnessMap', 'metalnessMap']
        
        for (const prop of textureProperties) {
          if (material[prop] && typeof material[prop].dispose === 'function') {
            material[prop].dispose()
          }
        }

        // Dispose the material itself
        if (typeof material.dispose === 'function') {
          material.dispose()
        }
      }
    } catch (error) {
      log.error('Error disposing material:', error, material)
    }
  }

  isDisposed() {
    return this.disposed
  }

  // Helper method for Three.js scene cleanup
  static disposeScene(scene) {
    if (!scene) return

    const toDispose = []
    
    scene.traverse((object) => {
      toDispose.push(object)
    })

    // Dispose in reverse order to handle parent-child relationships
    for (let i = toDispose.length - 1; i >= 0; i--) {
      const object = toDispose[i]
      
      // Remove from parent
      if (object.parent) {
        object.parent.remove(object)
      }

      // Dispose geometry
      if (object.geometry && typeof object.geometry.dispose === 'function') {
        object.geometry.dispose()
      }

      // Dispose material
      if (object.material) {
        DisposableResource.prototype.disposeMaterial(object.material)
      }
    }
  }

  // Helper method to get memory usage information
  static getMemoryInfo() {
    const info = {
      supported: false,
      usedJSHeapSize: 0,
      totalJSHeapSize: 0,
      jsHeapSizeLimit: 0
    }

    if (performance.memory) {
      info.supported = true
      info.usedJSHeapSize = performance.memory.usedJSHeapSize
      info.totalJSHeapSize = performance.memory.totalJSHeapSize
      info.jsHeapSizeLimit = performance.memory.jsHeapSizeLimit
    }

    return info
  }
}