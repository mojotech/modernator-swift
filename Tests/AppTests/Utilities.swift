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

func makeTestRequest(method: HTTP.Method, path: String, json: JSON) throws -> Request {
    return Request(method: method, uri: "/" + path, headers: ["Content-Type": "application/json"], body: try Body(json))
}
