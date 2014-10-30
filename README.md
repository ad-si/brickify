# Lowfab

## Installation

`$ git clone https://bitbucket.org/hpihci/fab3d-lowfab.git`

`$ cd fab3d-lowfab`

`$ npm install`


## Start Server

`$ npm start`

In order to continuously rebuild the project and restart the server
when source files change you can use supervisor.
Install it globally with `$ npm install -g supervisor` and use it like this:
`$ supervisor -i build -e node,coffee -- node_modules/coffee-script/bin/cake start`


## Tasks

Run `$ ./node_modules/.bin/cake` to list available tasks.


## Package management

We use [bower](http://bower.io/) for frontend package management.


## Documentation

We use [groc](http://nevir.github.io/groc/) for code documentation and [CroJSDoc](http://croquiscom.github.io/crojsdoc/) for api documentation.

Call `$ npm run-script documentation` and `$ npm run-script apiDocumentation` respectively.
