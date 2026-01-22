declare module 'winston' {
  interface Logger {
    error(...args: unknown[]): void;
    warn(...args: unknown[]): void;
    info(...args: unknown[]): void;
    http(...args: unknown[]): void;
    verbose(...args: unknown[]): void;
    debug(...args: unknown[]): void;
    silly(...args: unknown[]): void;
    log(level: string, ...args: unknown[]): void;
  }

  interface Loggers {
    get(name: string): Logger;
    add(name: string, options?: unknown): Logger;
    has(name: string): boolean;
    close(name?: string): void;
  }

  const loggers: Loggers;
  function createLogger(options?: unknown): Logger;

  // Top-level logging methods (when used as winston.info() etc)
  function error(...args: unknown[]): void;
  function warn(...args: unknown[]): void;
  function info(...args: unknown[]): void;
  function http(...args: unknown[]): void;
  function verbose(...args: unknown[]): void;
  function debug(...args: unknown[]): void;
  function silly(...args: unknown[]): void;

  export { Logger, Loggers, loggers, createLogger, error, warn, info, http, verbose, debug, silly };
}
