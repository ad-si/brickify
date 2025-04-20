# Brickify

## Installation

`$ git clone https://github.com/brickify/brickify.git`

`$ cd brickify`

Install dependencies: `$ npm install`

Link git hooks for automatic code tests and style checks:
`$ npm run linkHooks`


## Start Server

`$ npm start`

In order to continuously rebuild the project and restart the server
when source files change you can use supervisor.
Install it globally with `$ npm install -g supervisor` and use it like this:
`$ supervisor -i build -e node -- make start`
(Only necessary for server-side scripts as front-end gets build on the fly.)


## Scripts

Run `$ npm run` to list available scripts.
Execute a script like: `$ npm run <script-name>`

Following scripts are currently available:

- `build`: Builds client and server js files
- `start`: Starts server
- `apiDocumentation`: Generates API documentation
- `documentation`: Generates code documentation
- `test`: Executes headless tests
- `testClient`: Executes frontend tests in the browser
- `batchTest`: Batch test all models and create a HTML report
- `prepublish`: Prepares publication of project


## Package management

We use [npm](https://npmjs.org) for package management.
In order to bundle the modules for the browser we use [browserify](http://browserify.org).


## Styleguide

The code must be formatted as described in
https://github.com/style-guides/JavaScript


## Server

The server currently serves:

- [brickify.it](http://brickify.it): current master-branch
- [dev.brickify.it](http://dev.brickify.it): current develop-branch
