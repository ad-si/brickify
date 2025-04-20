let lastTarget = null

module.exports.init = function (callback) {
  const target = document.body
  const overlay = addOverlay(target)
  return bindDropHandler(target, overlay, callback)
}

var addOverlay = function (target) {
  const overlay = document.createElement("div")
  overlay.className = "modal-backdrop"
  overlay.id = "dropoverlay"
  overlay.style.opacity = 0
  overlay.style.transition = "opacity .1s ease-in-out"
  overlay.innerHTML =
  "<div id=\"dropborder\"> \
<div id=\"dropinfo\" class=\"text-center\">drop here</div> \
</div>"
  target.appendChild(overlay)
  return overlay
}

var bindDropHandler = function (target, overlay, callback) {
  target.addEventListener("drop", (event) => {
    hideOverlay(overlay)
    callback(event)
    return stopEvent(event)
  })
  target.addEventListener("dragover", event => stopEvent(event))
  target.addEventListener("dragenter", (event) => {
    stopEvent(event)
    showOverlay(overlay)
    return lastTarget = event.target
  })
  return target.addEventListener("dragleave", (event) => {
    if (event.target !== lastTarget) {
      return
    }
    stopEvent(event)
    return hideOverlay(overlay)
  })
}

var showOverlay = overlay => overlay.style.opacity = "0.8"

var hideOverlay = overlay => overlay.style.opacity = "0"

var stopEvent = function (event) {
  event.preventDefault()
  return event.stopPropagation()
}
