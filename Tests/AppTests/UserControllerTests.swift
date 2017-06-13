import XCTest
import Foundation
import Testing
import HTTP
@testable import Vapor
@testable import App

class UserControllerTests: TestCase {
    let drop = try! Droplet.testable()

    func testCreate() throws {
        let req_bad = try makeTestRequest(method: .post, path: "/users")
        try drop
            .testResponse(to: req_bad)
            .assertStatus(is: .badRequest)


        let req = try makeTestRequest(method: .post, path: "users", json: JSON(node: ["userName": "testcreate", "userPassword": "testcreatepassword"]))
        try drop
            .testResponse(to: req)
            .assertStatus(is: .ok)
    }

    func testLogin() throws {
        let req_bad = try makeTestRequest(method: .post, path: "users/login")
        try drop
            .testResponse(to: req_bad)
            .assertStatus(is: .badRequest)


        let username = "testuserslogin"
        let password = "testusersloginpassword"

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


        let username = "testusersme"
        let password = "testusersmepassword"

        let user = User(username: username, password: try drop.hash.make(password).makeString())
        try user.save()

        let req = try makeTestRequest(method: .get, path: "users/me");
        req.auth.authenticate(user)

        try drop
            .testResponse(to: req)
            .assertStatus(is: .ok)
            .assertJSON("userName", equals: username)
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
