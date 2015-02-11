require('es6-promise').polyfill()

path = require 'path'
r = require 'react'
$ = require 'jquery'
globalConfig = require '../common/globals.yaml'
Bundle = require './bundle'

window.jQuery = window.$ = require 'jquery'
bootstrap = require 'bootstrap'
ZeroClipboard = require 'zeroclipboard'


commandFunctions = {
	initialModel: (value) ->
		console.log 'loading initial model'
		p = /^[0-9a-z]{32}/
		if p.test value
			bundle.modelLoader.loadByHash value
		else
			console.warn 'Invalid value for initialModel'
}

postInitCallback = () ->
	#look at url hash and run commands
	hash = window.location.hash
	hash = hash.substring 1, hash.length
	commands = hash.split '+'
	for cmd in commands
		key = cmd.split('=')[0]
		value = cmd.split('=')[1]
		if commandFunctions[key]?
			commandFunctions[key](value)

	#clear url hash after executing commands
	window.location.hash = ''

bundle = new Bundle globalConfig
bundle.init().then(postInitCallback)

#init share logic
Promise.resolve($.get '/share').then((link) ->
	ZeroClipboard.config(
		{swfPath: '/node_modules/zeroclipboard/dist/ZeroClipboard.swf'})
	url = document.location.origin + '/app?share=' + link
	$('#cmdShare').tooltip({placement: 'bottom'}).click () ->
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
				copyButton.html 'Copied <span class="glyphicon glyphicon-ok"></span>'
				copyButton.addClass 'btn-success'
)

# Enable bootstrap tooltip
$('[data-toggle="tooltip"]').tooltip()
