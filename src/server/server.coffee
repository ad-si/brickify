###
  #IntelliJ Server start script

  This script is solely used by IntelliJ for being able to start the server
  from inside the IDE and debug javascript there.

  To be able to start the server via IntelliJ you need to install the
  NodeJS IntelliJ plugin and create a new run configuration.

  Use these settings:
  - **Node interpreter**: IntelliJ should insert the correct path to your node
    executable itself.
  - **Working directory**:
    insert the path to the root repository folder of brickify
  - **JavaScript file**: insert `src/server/server.js`
  - Add an external tool in the **Before launch** section
      - Give it any name you want
      - point it to the npm executable in the **Program** field
      - give it `$ run build` as **Parameters**
      - choose the same **Working directory** as before
  - If you want to see additional debug information such as the FPS counter add
    the **Environment variable** `NODE_ENV = development`


  If you run the server from IntelliJ while no server.js script is present,
  you will need to confirm to continue anyway. As long as you don't delete the
  server.js file, you won't need to confirm this again, but can just click on
  run to rebuild and run the server.
###

# Require the real server application and start the server
require './main'
.setupRouting()
.startServer()
