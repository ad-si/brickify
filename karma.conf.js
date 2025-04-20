export default function (config) {
  return config.set({

    // base path that will be used to resolve all patterns
    // (e.g. files, exclude)
    basePath: "",

    // frameworks to use
    // available frameworks: npmjs.org/browse/keyword/karma-adapter
    frameworks: [
      "browserify",
      "mocha",
      "chai",
      "chai-as-promised",
    ],

    // list of files/patterns to load in the browser
    files: [
      {
        pattern: "testClient/**/*.js",
        included: true,
      },
    ],

    // list of files to exclude
    exclude: [],

    // preprocess matching files before serving them to the browser
    // available preprocessors: npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
      "**/*.js": ["browserify"],
    },


    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: npmjs.org/browse/keyword/karma-reporter
    reporters: ["progress"],

    // web server port
    port: 9876,

    // enable / disable colors in the output (reporters and logs)
    colors: true,

    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR ||
    // config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_DEBUG,

    // enable/disable watching file and executing tests
    // whenever any file changes
    autoWatch: true,

    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: false,

    browserify: {
      debug: true,
      transform: [
        "browserify-data",
      ],
      extensions: [".js"],
    }})
}
