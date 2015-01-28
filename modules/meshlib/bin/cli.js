#! /usr/bin/env node

require('coffee-script').register()

var fs = require('fs'),
	program = require('commander'),
	meshlib = require('../index'),
	packageData = require('../package.json'),
	indent = '\n\t\t\t      '


program
	.version(packageData.version)
	.option(
		'-e, --encoding [value]',
		'Set encoding of output-file. Options: binary (default), utf-8' +
		indent + 'Only available for some file formats (e.g. stl)'
	)
	.option(
		'--input-encoding [value]',
		'Force read of input file with specified encoding (e.g. binary, utf-8).' +
		indent + 'Otherwise automatic recognition.'
	)
	.usage('<input-file> [options] <output-file>')
	.parse(process.argv)


if (program.args.length < 2)
	program.help()

else
	fs.readFile(program.args[0], function (error, fileBuffer) {

		if (error)
			throw error

		meshlib.parse(fileBuffer, null, function (error, model) {

			if (error)
				throw error

			fs.writeFileSync(program.args.pop(), JSON.stringify(model))
		})
	})
