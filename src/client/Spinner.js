/*
 * A reentrant-save spinner that can be invoked for a html target node.
 * @module Spinner
 */
import Spin from "spin"
import $ from "jquery"

const spinners = new Map()
const defaultTarget = document.createElement("div")
defaultTarget.id = "body-spinner"
document.body.appendChild(defaultTarget)

const defaults = {
  lines: 12,
  length: 7,
  width: 5,
  radius: 10,
  rotate: 0,
  corners: 1,
  color: "#fff",
  direction: 1,
  speed: 1,
  trail: 100,
  opacity: 1 / 4,
  fps: 20,
  zIndex: 2e9,
  className: "spinner",
  top: "50%",
  left: "50%",
  position: "absolute",
  shadow: true,
  hwaccel: true,
}

const addDefaults = options => (() => {
  const result = []
  for (const key in defaults) {
    const value = defaults[key]
    result.push(options[key] != null ? options[key] : options[key] = value)
  }
  return result
})()


/*
 * Starts a spinner attached to the given target node.
 * @param {DOMNode} [target=document.body] the target node
 * @return {Number} the number of start invocations of this spinner
 * @memberOf Spinner
 */
export function start (target, options) {
  if (options == null) {
    options = {}
  }
  if (target == null) {
    target = defaultTarget
  }
  addDefaults(options)

  let spinnerState = spinners.get(target)
  if (spinnerState == null) {
    const spin = new Spin(options)
      .spin()
    target.appendChild(spin.el)
    spinnerState = {spin, count: 0}
    spinners.set(target, spinnerState)
  }

  return ++spinnerState.count
}


/*
 * Starts a spinner located centered above the given target node.
 * @param {DOMNode} [target=document.body] the target node
 * @return {Number} the number of start invocations of this spinner
 * @memberOf Spinner
 */
export function startOverlay (target, options) {
  if (options == null) {
    options = {}
  }
  if (target == null) {
    return start(null, options)
  }
  addDefaults(options)

  let spinnerState = spinners.get(target)
  if (spinnerState == null) {
    const spin = new Spin(options)
      .spin()
    const overlay = document.createElement("div")
    overlay.className = "overlay-spinner"
    overlay.appendChild(spin.el)
    const $target = $(target)
    const offset = $target.offset()
    const top = offset.top + ($target.height() / 2)
    const left = offset.left + ($target.width() / 2)
    overlay.style.cssText = `top: ${top}px; left: ${left}px;`
    document.body.appendChild(overlay)
    spinnerState = {spin, count: 0, overlay}
    spinners.set(target, spinnerState)
  }

  return spinnerState.count++
}


/*
 * Stops a spinner associated with the given target node.
 * @param {DOMNode} [target=document.body] the target node
 * @return {Number} the number of remaining start invocations of this spinner
 * @memberOf Spinner
 */
export function stop (target) {
  if (target == null) {
    target = defaultTarget
  }

  const spinnerState = spinners.get(target)
  if (!spinnerState) {
    return
  }

  spinnerState.count--
  if (spinnerState.count > 0) {
    return spinnerState.count
  }

  spinnerState.spin.stop()

  if (spinnerState.overlay != null) {
    document.body.removeChild(spinnerState.overlay)
  }

  spinners.delete(target)
  return 0
}
