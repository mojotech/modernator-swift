import Foundation
@testable import App
@testable import Vapor
import XCTest
import Testing
import FluentProvider
import HTTP

extension Droplet {
    static func testable() throws -> Droplet {
        let config = try Config(arguments: ["vapor", "--env=test"])
        try config.setup()
        let drop = try Droplet(config)
        try drop.setup()
        return drop
    }
    func serveInBackground() throws {
        background {
            try! self.run()
        }
        console.wait(seconds: 0.5)
    }
}

class TestCase: XCTestCase {
    override func setUp() {
        Node.fuzzy = [Row.self, JSON.self, Node.self]
        Testing.onFail = XCTFail
    }
}

func makeTestRequest(method: HTTP.Method, path: String, json: JSON? = nil) throws -> Request {
    let req = Request(method: method, uri: "/" + path)

    if (json != nil) {
        assert(method != .get)
        req.headers["Content-Type"] = "application/json"
        req.body = try Body(json!)
    }

    return req
}
