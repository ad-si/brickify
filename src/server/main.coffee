sys = require("sys")
my_http = require("http")
path = require("path")
url = require("url")
filesys = require("fs")

server = my_http.createServer ( request, response ) ->
	
	my_path = url.parse( request.url ).pathname
	full_path = path.join( process.cwd(), my_path )
	
	filesys.exists full_path, ( exists ) -> 
		if not exists
			response.writeHeader( 404, { "Content-Type": "text/plain" } )
			response.write( "404 Not Found\n" )
			response.end()
		else
			filesys.readFile full_path, "binary", ( err, file ) ->
				if err
					response.writeHeader( 500, { "Content-Type": "text/plain" } )
					response.write( err + "\n" )
					response.end()
				else
					response.writeHeader( 200 )
					response.write( file, "binary" )
					response.end()


server.listen( 8080 )
sys.puts( "Server Running on 8080" )