// Colorful logger for console
import winston from "winston"
const logger = winston.loggers.get("log")

module.exports.init = () => logger.debug("Dummy Server Folder-Plugin initialization")
