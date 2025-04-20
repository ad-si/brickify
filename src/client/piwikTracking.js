export function trackEvent (category, action,
  name = null, numericValue = null) {
  if (typeof _paq !== "undefined" && _paq !== null) {
    return _paq.push(
      ["trackEvent", category, action, name, numericValue],
    )
  }
}

export function setCustomSessionVariable (slot, name, content) {
  if (typeof _paq !== "undefined" && _paq !== null) {
    return _paq.push(
      ["setCustomVariable", slot, name, content, "visit"],
    )
  }
}
