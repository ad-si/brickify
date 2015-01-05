# Lowfab

## Installation

`$ git clone https://github.com/stuikomma/lowfab.git`

`$ cd lowfab`

Install dependencies: `$ npm install`

Link git hooks for automatic code tests and style checks:
`$ npm run linkHooks`


## Start Server

`$ npm start`

In order to continuously rebuild the project and restart the server
when source files change you can use supervisor.
Install it globally with `$ npm install -g supervisor` and use it like this:
`$ supervisor -i build -e node,coffee -- node_modules/coffee-script/bin/cake start`
(Only necessary for server-side scripts as front-end gets build on the fly.)


## Scripts

Run `$ npm run` to list available scripts.
Execute a script like: `$ npm run <script-name>`

Following scripts are currently available:

- `build`: Builds client and server js files
- `start`: Starts server
- `linkHooks`: Links git hooks
- `checkStyle`: Checks code-style of coffeescript files
- `apiDocumentation`: Generates API documentation
- `documentation`: Generates code documentation
- `test`: Executes headless tests
- `testFrontend`: Executes frontend tests
- `batchTest`: Batch test all models and create a HTML report
- `prepublish`: Prepares publication of project


## Package management

We use [npm](https://npmjs.org) for package management.
In order to bundle the modules for the browser we use [browserify](http://browserify.org)
The usage of bower is deprecated and we will remove the remaining libraries in the future.


## Documentation

We use [groc](http://nevir.github.io/groc/) for code documentation
and [CroJSDoc](http://croquiscom.github.io/crojsdoc/) for api documentation.

Call `$ npm run documentation` and
`$ npm run apiDocumentation` respectively.

## Server

The server currently serves:

- [lowfab.net](http://lowfab.net): current master-branch
- [dev.lowfab.net](http://dev.lowfab.net): current develop-branch
- [batchtests.lowfab.net](http://batchtests.lowfab.net): results of batchTesting (performed on develop)
