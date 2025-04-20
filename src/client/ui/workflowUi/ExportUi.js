import ShareUi from "./ShareUi.js"
import DownloadUi from "./DownloadUi.js"

export default class ExportUi {
  constructor (workflowUi) {
    this.setEnabled = this.setEnabled.bind(this)
    this._initShare = this._initShare.bind(this)
    this._initDownload = this._initDownload.bind(this)
    this.$panel = $("#exportGroup")
    this.bundle = workflowUi.bundle

    this._initShare()
    this._initDownload()
  }

  setEnabled (enabled) {
    this.$panel.find("h4")
      .toggleClass("disabled", !enabled)
    this.shareUi.setEnabled(enabled)
    return this.downloadUi.setEnabled(enabled)
  }

  _initShare () {
    return this.shareUi = new ShareUi(this)
  }

  _initDownload () {
    return this.downloadUi = new DownloadUi(this.bundle)
  }
}
