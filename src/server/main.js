import { exec } from "child_process"
import http from "http"
import path from "path"
import fsp from "fs/promises"

import bootstrap from "bootstrap-styl"
import winston from "winston"
import express from "express"
import bodyParser from "body-parser"
import compress from "compression"
import morgan from "morgan"
import errorHandler from "errorhandler"
import favicon from "serve-favicon"
import stylus from "stylus"
import nib from "nib"
import yaml from "js-yaml"
import cookieParser from "cookie-parser"

import * as urlSessions from "./urlSessions.js"

const __dirname = import.meta.dirname

// Make logger available to other modules.
// Must be instantiated before requiring bundled modules
winston.loggers.add("log", {
  console: {
    level: loggingLevel,
    colorize: true,
  },
})
const log = winston.loggers.get("log")

import * as pluginLoader from "./pluginLoader.js"
import app from "../../routes/app.js"
import * as landingPage from "../../routes/landingpage.js"
import * as models from "../../routes/models.js"
import * as dataPackets from "../../routes/dataPackets.js"
import sharelinkGen from "../../routes/share.js"
const globalConfig = yaml.safeLoad(
  await fsp.readFile(path.resolve(__dirname, "../common/globals.yaml"), "utf8")
)

const webapp = express()

// Express assumes that no env means develop.
// Therefore override it to make it clear for all
const developmentMode = webapp.get("env") === "development"
if (developmentMode) {
  process.env.NODE_ENV = "development"
  log.info("development mode activated")
}
else {
  log.info("production mode activated")
}

const testMode = webapp.get("env") === "test"

var loggingLevel = developmentMode ? "debug" : "warn"
if (testMode) {
  loggingLevel = "error"
}


export async function setupRouting (port) {
  webapp.set("hostname", developmentMode ? `localhost:${port}`
    : process.env.HOSTNAME || "brickify.it",
  )

  webapp.set("views", path.normalize("views"))
  webapp.set("view engine", "jade")

  webapp.use(favicon(path.normalize("public/img/favicon.png", {maxAge: 1000})))

  webapp.use(compress())

  webapp.use(stylus.middleware({
    src: path.resolve(__dirname, "../../public"),
    dest: path.resolve(__dirname, "../../public"),
    compile (string, filePath) {
      return stylus(string)
        .set("filename", filePath || "")
        .set("compress", !developmentMode)
        .set("sourcemap", developmentMode ? {
          comment: true,
          inline: true,
          basePath: path.resolve(__dirname, "../../public")
        } : false)
        .set("include css", true)
        .set("paths", [
          path.resolve(__dirname, "../../public/styles"),
          path.resolve(__dirname, "../../node_modules")
        ])
        .use(nib())
        .use(bootstrap())
      // Ugly because of github.com/LearnBoost/stylus/issues/1828
        .define("backgroundColor", "#" + ("000000" +
        globalConfig.colors.background.toString(16)).slice(-6))
    },
  }))

  webapp.use((_req, res, next) => {
    res.locals.app = webapp
    return next()
  })


  const fontAwesomeRegex = /\/fonts\/fontawesome-.*/
  webapp.get(fontAwesomeRegex, express.static("node_modules/font-awesome/"))

  webapp.use(express.static("public"))
  webapp.use("/node_modules", express.static("node_modules"))

  if (developmentMode) {
    webapp.use(morgan("dev", {
      stream: {
        write (str) {
          return log.info(str.substring(0, str.length - 1))
        },
      },
    },
    ),
    )
  }
  else {
    webapp.use(morgan("combined", {
      stream: {
        write (str) {
          return log.info(str.substring(0, str.length - 1))
        },
      },
    },
    ),
    )
  }

  webapp.use(cookieParser())
  webapp.use(urlSessions.middleware)

  const jsonParser = bodyParser.json({limit: "100mb"})
  const urlParser = bodyParser.urlencoded({extended: true, limit: "100mb"})
  const rawParser = bodyParser.raw({limit: "100mb"})

  webapp.get("/", landingPage.getLandingpage)
  webapp.get("/contribute", landingPage.getContribute)
  webapp.get("/team", landingPage.getTeam)
  webapp.get("/imprint", landingPage.getImprint)
  webapp.get("/educators", landingPage.getEducators)
  webapp.get("/app", app)
  webapp.get("/share", sharelinkGen)

  webapp.route("/model/:identifier")
    .head(models.exists)
    .get(models.get)
    .put(rawParser, models.store)

  webapp.post("/datapacket", urlParser, dataPackets.create)
  webapp.route("/datapacket/:id")
    .head(dataPackets.exists)
    .get(dataPackets.get)
    .put(jsonParser, dataPackets.put)
    .delete(dataPackets.delete_)

  webapp.post("/updateGitAndRestart", jsonParser, (request, response) => {
    if (request.body.ref != null) {
      const {
        ref,
      } = request.body
      if (!((ref.indexOf("develop") >= 0) || (ref.indexOf("master") >= 0))) {
        log.debug('Got a server restart command, but "ref" ' +
          "did not contain develop or master",
        )
        response.send("")
        return
      }
    }
    else {
      log.warn('Got a server restart command without a "ref" ' +
        "json member from " + request.connection.remoteAddress,
      )
      response.send("")
      return
    }

    response.send("")
    return exec("../updateAndRestart.sh", (error, out, code) => {
      if (error) {
        return log.warn(`Error while updating server: ${error}`)
      }
    })
  })

  await pluginLoader.loadPlugins(path.resolve(__dirname, "../plugins"))

  if (developmentMode) {
    webapp.use(errorHandler())
  }

  webapp.use((_req, res) => res
    .status(404)
    .render("404"))
}


export async function startServer (_port, _ip) {
  const server = http.createServer(webapp)
  const srvrPort = _port || process.env.NODEJS_PORT || process.env.PORT || 3000
  const srvrIp = _ip || process.env.NODEJS_IP || "127.0.0.1"

  server.on("error", (error) => {
    if (error.code === "EADDRINUSE") {
      return log.error(`Another Server is already listening on ${srvrIp}:${srvrPort}`)
    }
    else {
      return log.error("Server could not be started:", error)
    }
  })

  await setupRouting(srvrPort)

  server.listen(
    srvrPort,
    srvrIp,
    () => log.info(`Server is listening on ${srvrIp}:${srvrPort}`),
  )
}
