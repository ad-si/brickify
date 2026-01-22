// TODO: Fix this test

// process.env.NODE_ENV = "test"

// import chai from "chai"
// import http from "http"

// import brickify from "../src/server/main.js"

// const { expect } = chai


// describe("Brickify", () => {
//   let server = {}

//   before(function (done) {
//     this.timeout(5000)

//     server = brickify
//       .setupRouting()
//       .startServer(3001)

//     return done()
//   })

//   describe("Server", () => {
//     it("should host the brickify website", function (done) {
//       this.timeout(5000)
//       const request = http.request(
//         {method: "HEAD", host: "localhost", port: 3001},
//         (response) => {
//           expect(response.statusCode).to.equal(200)
//           return done()
//         },
//       )

//       return request.end()
//     })
//   })

//   after(() => server.close())
// })
