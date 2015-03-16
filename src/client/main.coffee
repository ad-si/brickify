require('es6-promise').polyfill()
require 'PEP'

path = require 'path'
$ = require 'jquery'
globalConfig = require '../common/globals.yaml'
Bundle = require './bundle'

window.jQuery = window.$ = require 'jquery'
bootstrap = require 'bootstrap'
ZeroClipboard = require 'zeroclipboard'


commandFunctions = {
	initialModel: (value) ->
		# load selected model
		console.log 'loading initial model'
		p = /^[0-9a-z]{32}/
		if p.test value
			bundle.sceneManager.clearScene()
			bundle.modelLoader.loadByHash value
		else
			console.warn 'Invalid value for initialModel'
}

postInitCallback = ->
	#look at url hash and run commands
	hash = window.location.hash
	hash = hash.substring 1, hash.length
	commands = hash.split '+'
	prom = Promise.resolve()
	runCmd = (key, value) -> -> Promise.resolve commandFunctions[key](value)
	for cmd in commands
		key = cmd.split('=')[0]
		value = cmd.split('=')[1]
		if commandFunctions[key]?
			prom = prom.then runCmd key, value

	#clear url hash after executing commands
	window.location.hash = ''

bundle = new Bundle globalConfig
bundle.init().then(postInitCallback)

Promise.resolve($.get '/share').then((link) ->
	#init share logic
	ZeroClipboard.config(
		{swfPath: '/node_modules/zeroclipboard/dist/ZeroClipboard.swf'})
	url = document.location.origin + '/app?share=' + link
	$('#cmdShare').tooltip({placement: 'bottom'}).click ->
		bundle.saveChanges().then(
			bootbox.dialog({
				title: 'Share your work!'
				message: '<label for="shareUrl">Via URL:</label>
				<input id="shareUrl" class="form-control not-readonly"
				type="text" value="' + url + '" onClick="this.select()" readonly>
				<div id="copy-button" class="btn btn-primary copy-button"
				data-clipboard-text="' + url + '">Copy</div>'
			})
		)
		copyButton = $('#copy-button')
		client = new ZeroClipboard copyButton

		client.on 'ready', (readyEvent) ->
			client.on 'aftercopy', (event) ->
				copyButton.html 'Copied <span class="fa fa-check"></span>'
				copyButton.addClass 'btn-success'

	#init direct help
	$('#cmdHelp').tooltip({placement: 'bottom'}).click ->
		bundle.ui.hotkeys.showHelp()
)
