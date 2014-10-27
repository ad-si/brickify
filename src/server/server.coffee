# Makes it possible to directly require coffee modules
require 'coffee-script/register'

server = require './main.js'

server.startServer()
