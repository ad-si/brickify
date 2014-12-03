path = require 'path'
r = require 'react'

globalConfig = require './globals.yaml'
ui = require('./ui')(globalConfig)
pluginLoader = require './pluginLoader'
statesync = require './statesync'
objectTree = require '../common/objectTree'


menuItems = [
	{
		name: 'Import'
		icon: 'fa-plus'
		listItems: [
			{name: 'Upload file', icon: 'fa-upload'}
			{name: 'Download from cloud', icon: 'fa-cloud-download'}
		]
	}
	{
		name: 'View'
		icon: 'fa-columns'
		listItems: [
			{name: 'Front', icon: 'fa-dot-circle-o'}
			{name: 'Back', icon: 'fa-times-circle-o'}
			{name: 'Top', icon: 'fa-arrow-circle-o-down'}
			{name: 'Bottom', icon: 'fa-arrow-circle-o-up'}
			{name: 'Left', icon: 'fa-arrow-circle-o-right'}
			{name: 'Right', icon: 'fa-arrow-circle-o-left'}
			{name: '-'}
			{name: 'Hide Grid', icon: 'fa-table'}
			{name: 'Hide Axis', icon: 'fa-plus-square-o'}
			{name: 'Show Wireframe', icon: 'fa-paper-plane-o'}
			{name: '-'}
			{name: 'Orthogonal', icon: 'fa-square-o'}
			{name: 'Perspective', icon: 'fa-inbox'}
		]
	}
	{
		name: 'Export'
		icon: 'fa-sign-out'
		listItems: [
			{name: 'STL', icon: 'fa-file-text-o'}
			{name: 'OBJ', icon: 'fa-file-text-o'}
			{name: 'AMF', icon: 'fa-file-text-o'}
			{name: 'PLY', icon: 'fa-file-text-o'}
		]
	}
]

# Generate UI
dom = r.DOM

listItem = r.createClass {
	displayName: 'listItem',
	render: () ->

		if this.props.name is '-'
			return dom.li({className: 'divider', role: 'presentation'})

		else
			return dom.li({},
				dom.a(
					{href: '#'},
					dom.span(
						{className: 'fa ' + this.props.icon},
						' ' + this.props.name
					)
				)
			)
}

menuItem = r.createClass {
	displayName: 'menuItem',
	render: () ->
		return dom.li(
			{className: 'dropdown'},
			dom.a(
				className: 'dropdown-toggle',
				'data-toggle': 'dropdown',
				dom.span({className: 'fa fa-fw fa-lg ' + this.props.icon}),
				this.props.name,
				dom.span({className: 'caret'}),
				dom.ul(
					className: 'dropdown-menu',
					role: 'menu',
					this.props.listItems.map (item) ->
						return r.createElement listItem, item
				)
			)
		)
}

menuList = r.createClass {
	displayName: 'menuList',
	render: () ->
		return dom.ul(
			{className: 'nav navbar-nav'},
			this.props.items.map (item) ->
				return r.createElement menuItem, item
		)
}

r.render(
	r.createElement(menuList, {className: 'Test', items: menuItems}),
	document.querySelector '#navbarToggle'
)


ui.init()


### TODO: move somewhere where it is needed
# geometry functions
degToRad = ( deg ) -> deg * ( Math.PI / 180.0 )
radToDeg = ( rad ) -> deg * ( 180.0 / Math.PI )

normalFormToParamterForm = ( n, p, u, v) ->
	u.set( 0, -n.z, n.y ).normalize()
	v.set( n.y, -n.x, 0 ).normalize()

# utility
String::contains = (str) -> -1 isnt this.indexOf str
###

statesync.init globalConfig, (state) ->
	objectTree.init state
	pluginLoader.init globalConfig
	pluginLoader.loadPlugins()

	#look at url hash and run commands
	hash = window.location.hash
	hash = hash.substring 1, hash.length
	commands = hash.split '+'
	for cmd in commands
		key = cmd.split('=')[0]
		value = cmd.split('=')[1]
		if commandFunctions[key]?
			commandFunctions[key](state, value)

	#clear url hash after executing commands
	window.location.hash = ''


commandFunctions = {
	initialModel: (state, value) ->
		console.log 'loading initial model'
		stlImport = require './plugins/stlImport/stlImport'
		p = /^[0-9a-z]{32}\.optimized$/
		if p.test value
			stlImport.importHash value
		else
			console.warn 'Invalid value for initialModel'
}

