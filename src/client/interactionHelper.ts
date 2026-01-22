/*
 * @module interactionHelper
 */

import THREE, { type Object3D, type Intersection, type PerspectiveCamera, type Vector3 } from "three"

interface PointerEvent {
  clientX: number;
  clientY: number;
}

interface BrickifyRenderer {
  getCamera(): PerspectiveCamera;
  getDomElement(): HTMLCanvasElement;
}

interface BrickifyObject3D extends Object3D {
  associatedPlugin?: unknown;
}

/*
 * Determines the intersections a ray casted by a screen space interaction hits
 * @param {Object} event usually a mouse or tap or pointer event
 * @param {Number} event.pageX the x coordinate on the screen
 * @param {Number} event.pageY the y coordinate on the screen
 * @param {Renderer} renderer the renderer that provides the camera and canvas
 * @param {Array<Object>} objects the three nodes which take part in ray casting
 * @return {Array<Object>} an array of intersections
 * @memberOf interactionHelper
 */
export function getIntersections (event: PointerEvent, renderer: BrickifyRenderer, objects: Object3D[]): Intersection[] {
  const ray = calculateRay(event, renderer)

  const raycaster = new THREE.Raycaster()
  raycaster.ray.set(renderer.getCamera().position, ray)

  return raycaster.intersectObjects(objects, true)
}

/*
 * Determines the responsible plugin for a screen space interaction based on
 * the first object that is intersected and has an associated plugin.
 * @param {Object} event usually a mouse or tap or pointer event
 * @param {Number} event.pageX the x coordinate on the screen
 * @param {Number} event.pageY the y coordinate on the screen
 * @param {Renderer} renderer the renderer that provides the camera and canvas
 * @param {Array<Object>} objects the three nodes which take part in ray casting
 * @param {Function} [filter] filter a filter function to ignore some plugins
 * @param {Plugin} filter.plugin a plugin to check for filtering
 * @return {Plugin|undefined} the name of the plugin
 * @memberOf interactionHelper
 */
export function getResponsiblePlugin (
  event: PointerEvent,
  renderer: BrickifyRenderer,
  objects: Object3D[],
  filter: (plugin: unknown) => boolean = () => true
): unknown {
  for (const intersection of getIntersections(event, renderer, objects)) {
    let object: BrickifyObject3D | null = intersection.object as BrickifyObject3D

    while (object != null) {
      const plugin = object.associatedPlugin
      if ((plugin != null) && filter(plugin)) {
        return plugin
      }
      object = object.parent as BrickifyObject3D | null
    }
  }

  return undefined
}

/*
 * Determines the position of an event on the z=0 plane
 * @param {Object} event usually a mouse or tap or pointer event
 * @param {Number} event.pageX the x coordinate on the screen
 * @param {Number} event.pageY the y coordinate on the screen
 * @param {Renderer} renderer the renderer that provides the camera and canvas
 * @return {Object} a vector {x, y, z}
 * @memberOf interactionHelper
 */
export function getGridPosition (event: PointerEvent, renderer: BrickifyRenderer): Vector3 {
  return getPlanePosition(event, renderer, 0)
}


/*
 * Determines the position of an event on the given z plane
 * @param {Object} event usually a mouse or tap or pointer event
 * @param {Number} event.pageX the x coordinate on the screen
 * @param {Number} event.pageY the y coordinate on the screen
 * @param {Renderer} renderer the renderer that provides the camera and canvas
 * @param {Number} z the z plane on which the interaction takes place
 * @return {Object} a vector {x, y, z}
 * @memberOf interactionHelper
 */
export function getPlanePosition (event: PointerEvent, renderer: BrickifyRenderer, z: number): Vector3 {
  const ray = calculateRay(event, renderer)

  const camera = renderer.getCamera()
  ray.multiplyScalar(-(camera.position.z - z) / ray.z)
  const posInWorld = camera.position.clone()
    .add(ray)

  return posInWorld
}

/*
 * Determines the position of an event in canvas space
 * @param {Object} event usually a mouse or tap or pointer event
 * @param {Number} event.clientX the x coordinate relative to the viewport
 * @param {Number} event.clientY the y coordinate relative to the viewport
 * @param {Renderer} renderer the renderer that provides the camera and canvas
 * @return {Object} a three vector
 * @memberOf interactionHelper
 */
export function calculatePositionInCanvasSpace (event: PointerEvent, renderer: BrickifyRenderer): Vector3 {
  const canvas = renderer.getDomElement()
  const rect = canvas.getBoundingClientRect()

  return new THREE.Vector3(
    (((event.clientX - rect.left) / rect.width) * 2) - 1,
    ((-(event.clientY - rect.top) / rect.height) * 2) + 1,
    0.5,
  )
}


/*
 * Determines the position of the event in camera space
 * @param {Object} event usually a mouse or tap or pointer event
 * @param {Number} event.pageX the x coordinate on the screen
 * @param {Number} event.pageY the y coordinate on the screen
 * @param {Renderer} renderer the renderer that provides the camera and canvas
 * @return {Object} a three vector
 * @memberOf interactionHelper
 */
export function calculatePositionInCameraSpace (event: PointerEvent, renderer: BrickifyRenderer): Vector3 {
  const positionInCanvasCS = calculatePositionInCanvasSpace(event, renderer)
  return positionInCanvasCS.unproject(renderer.getCamera())
}

/*
 * Determines a virtual ray that a screen space interaction casts
 * @param {Object} event usually a mouse or tap or pointer event
 * @param {Number} event.pageX the x coordinate on the screen
 * @param {Number} event.pageY the y coordinate on the screen
 * @param {Renderer} renderer the renderer that provides the camera and canvas
 * @return {Object} a normalized three vector {x, y, z}
 * @memberOf interactionHelper
 */
export function calculateRay (event: PointerEvent, renderer: BrickifyRenderer): Vector3 {
  const positionInCameraCS = calculatePositionInCameraSpace(event, renderer)
  return positionInCameraCS.sub(renderer.getCamera().position)
    .normalize()
}
