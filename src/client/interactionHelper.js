/*
 * @module interactionHelper
 */

import THREE from "three"

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
const getIntersections = function (event, renderer, objects) {
  const ray = calculateRay(event, renderer)

  const raycaster = new THREE.Raycaster()
  raycaster.ray.set(renderer.getCamera().position, ray)

  return raycaster.intersectObjects(objects, true)
}
module.exports.getIntersections = getIntersections

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
const getResponsiblePlugin = function (event, renderer, objects, filter) {
  if (filter == null) {
    filter = () => true
  }
  for (const intersection of Array.from(getIntersections(event, renderer, objects))) {
    let {
      object,
    } = intersection

    while (object != null) {
      const plugin = object.associatedPlugin
      if ((plugin != null) && filter(plugin)) {
        return plugin
      }
      object = object.parent
    }
  }

  return undefined
}
module.exports.getResponsiblePlugin = getResponsiblePlugin

/*
 * Determines the position of an event on the z=0 plane
 * @param {Object} event usually a mouse or tap or pointer event
 * @param {Number} event.pageX the x coordinate on the screen
 * @param {Number} event.pageY the y coordinate on the screen
 * @param {Renderer} renderer the renderer that provides the camera and canvas
 * @return {Object} a vector {x, y, z}
 * @memberOf interactionHelper
 */
const getGridPosition = (event, renderer) => getPlanePosition(event, renderer, 0)
module.exports.getGridPosition = getGridPosition

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
var getPlanePosition = function (event, renderer, z) {
  const ray = calculateRay(event, renderer)

  const camera = renderer.getCamera()
  ray.multiplyScalar(-(camera.position.z - z) / ray.z)
  const posInWorld = camera.position.clone()
    .add(ray)

  return posInWorld
}
module.exports.getPlanePosition = getPlanePosition

/*
 * Determines the position of an event in canvas space
 * @param {Object} event usually a mouse or tap or pointer event
 * @param {Number} event.pageX the x coordinate on the screen
 * @param {Number} event.pageY the y coordinate on the screen
 * @param {Renderer} renderer the renderer that provides the camera and canvas
 * @return {Object} a three vector
 * @memberOf interactionHelper
 */
const calculatePositionInCanvasSpace = function (event, renderer) {
  const canvas = renderer.getDomElement()

  return new THREE.Vector3(
    ((event.pageX / canvas.width) * 2) - 1,
    ((-event.pageY / canvas.height) * 2) + 1,
    0.5,
  )
}
module.exports.calculatePositionInCanvasSpace = calculatePositionInCanvasSpace

/*
 * Determines the position of the event in camera space
 * @param {Object} event usually a mouse or tap or pointer event
 * @param {Number} event.pageX the x coordinate on the screen
 * @param {Number} event.pageY the y coordinate on the screen
 * @param {Renderer} renderer the renderer that provides the camera and canvas
 * @return {Object} a three vector
 * @memberOf interactionHelper
 */
const calculatePositionInCameraSpace = function (event, renderer) {
  const positionInCanvasCS = calculatePositionInCanvasSpace(event, renderer)
  return positionInCanvasCS.unproject(renderer.getCamera())
}
module.exports.calculatePositionInCameraSpace = calculatePositionInCameraSpace

/*
 * Determines a virtual ray that a screen space interaction casts
 * @param {Object} event usually a mouse or tap or pointer event
 * @param {Number} event.pageX the x coordinate on the screen
 * @param {Number} event.pageY the y coordinate on the screen
 * @param {Renderer} renderer the renderer that provides the camera and canvas
 * @return {Object} a normalized three vector {x, y, z}
 * @memberOf interactionHelper
 */
var calculateRay = function (event, renderer) {
  const positionInCameraCS = calculatePositionInCameraSpace(event, renderer)
  return positionInCameraCS.sub(renderer.getCamera().position)
    .normalize()
}
module.exports.calculateRay = calculateRay
