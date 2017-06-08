import XCTest
import Foundation
import Testing
import HTTP
@testable import Vapor
@testable import App

class UserControllerTests: TestCase {
    let drop = try! Droplet.testable()

    func testCreate() throws {
        let req = Request(method: .post, uri: "/users")
        try drop
            .testResponse(to: req)
            .assertStatus(is: .badRequest)

        let reqCreate = try makeTestRequest(method: .post, path: "users", json: JSON(node: ["userName": "testun", "userPassword": "testpw"]))
        try drop
            .testResponse(to: reqCreate)
            .assertStatus(is: .ok)
    }

    func testLogin() throws {
        let username = "testlogin"
        let password = "testloginpassword"

        try User(username: username, password: try drop.hash.make(password).makeString()).save()

        let req = try makeTestRequest(method: .post, path: "users/login", json: JSON(node: ["loginName": username, "loginPassword": password]))
        try drop
            .testResponse(to: req)
            .assertStatus(is: .ok)
    }

    func testMe() throws {
        try drop
            .testResponse(to: .get, at: "users/me")
            .assertStatus(is: .forbidden)

        // TODO create user and actually test:
//        try drop
//            .testResponse(to: .get, at: "users/me")
//            .assertStatus(is: .ok)
//            .assertBody(contains: "{") // *some* JSON
    }
}

// MARK: Manifest

extension UserControllerTests {
    /// This is a requirement for XCTest on Linux
    /// to function properly.
    /// See ./Tests/LinuxMain.swift for examples
    static let allTests = [
        ("testCreate", testCreate),
        ("testLogin", testLogin),
        ("testMe", testMe)
    ]
}
