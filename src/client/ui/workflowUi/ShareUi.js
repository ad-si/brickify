import piwikTracking from "../../piwikTracking.js"

export default class ShareUi {
  constructor () {
    this.setEnabled = this.setEnabled.bind(this)
    this.$shareButton = $("#shareButton")
    this._initNotImplementedMessages()
  }

  _initNotImplementedMessages () {
    const alertCallback = () => bootbox.alert({
      title: "Not implemented yet",
      message: "We are sorry, but this feature is not implemented yet. \
Please check back later.",
    })

    return this.$shareButton.click(() => {
      piwikTracking.trackEvent(
        "trackEvent", "Editor", "ExportAction", "ShareButtonClick",
      )
      return alertCallback()
    })
  }

  setEnabled (enabled) {
    return this.$shareButton.toggleClass("disabled", !enabled)
  }
}
