# Lowfab

## Installation

`$ git clone https://adius@bitbucket.org/hpihci/fab3d-lowfab.git`

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
