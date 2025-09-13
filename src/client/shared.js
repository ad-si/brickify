// Shared dependencies that are used across multiple bundles
// Ensure jQuery and Bootstrap plugins attach to the same instance
import $ from "jquery"
window.jQuery = window.$ = $
// THREE is provided via ESM import and exposed globally for legacy plugins
import THREE from "three"
import md5 from "blueimp-md5"
import clone from "clone"
import "es6-promise"
import { saveAs } from "filesaver.js"
import Nanobar from "nanobar"
import "PEP"
import path from "path-browserify"
import "three-pointer-controls"
import ZeroClipboard from "zeroclipboard"

// Expose as globals for compatibility
window.md5 = md5
window.clone = clone
window.saveAs = saveAs
window.Nanobar = Nanobar
window.path = path
window.ZeroClipboard = ZeroClipboard
window.THREE = THREE
