# Lowfab

## Installation

`$ git clone https://bitbucket.org/hpihci/fab3d-lowfab.git`

`$ cd fab3d-lowfab`

Install dependencies: `$ npm install`

Link git hooks for automatic code tests and style checks:
`$ npm run-script linkHooks`


## Start Server

`$ npm start`

In order to continuously rebuild the project and restart the server
when source files change you can use supervisor.
Install it globally with `$ npm install -g supervisor` and use it like this:
`$ supervisor -i build -e node,coffee -- node_modules/coffee-script/bin/cake start`


## Scripts

Run `$ npm run` to list available scripts.
Execute a script like: `$ npm run-script <script-name>`

Following scripts are currently available:

- `build`: Builds client and server js files
- `start`: Starts server
- `linkHooks`: Links git hooks
- `checkStyle`: Checks code-style of coffeescript files
- `apiDocumentation`: Generates API documentation
- `documentation`: Generates code documentation
- `test`: Executes tests
- `prepublish`: Prepares publication of project


## Package management

We use [bower](http://bower.io/) for frontend package management
and [npm](https://npmjs.org/) for backend package management.


## Documentation

We use [groc](http://nevir.github.io/groc/) for code documentation
and [CroJSDoc](http://croquiscom.github.io/crojsdoc/) for api documentation.

Call `$ npm run-script documentation` and
`$ npm run-script apiDocumentation` respectively.
