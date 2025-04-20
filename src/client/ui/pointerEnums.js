module.exports.events = {
  PointerOver: "PointerOver",
  PointerEnter: "PointerEnter",
  PointerDown: "PointerDown",
  PointerMove: "PointerMove",
  PointerUp: "PointerUp",
  PointerCancel: "PointerCancel",
  PointerOut: "PointerOut",
  PointerLeave: "PointerLeave",
  GotPointerCapture: "GotPointerCapture",
  LostPointerCapture: "LostPointerCapture",
  ContextMenu: "ContextMenu",
}
Object.freeze(module.exports.events)

module.exports.buttonStates = {
  none: 0,
  left: 1,
  right: 2,
  middle: 4,
  x1: 8,
  x2: 16,
  eraser: 32,
}

Object.freeze(module.exports.buttonStates)
