import XCTest
import Foundation
import Testing
import HTTP
@testable import Vapor
@testable import App

class UserControllerTests: TestCase {
    let drop = try! Droplet.testable()

    func testCreate_bad() throws {
        let req = try makeTestRequest(method: .post, path: "/users")

        try drop
            .testResponse(to: req)
            .assertStatus(is: .badRequest)
    }

    func testCreate_success() throws {
        let req = try makeTestRequest(
            method: .post, path: "users",
            json: JSON(node: [
                "userName": "testcreate",
                "userPassword": "testcreatepassword"
            ])
        )

        try drop
            .testResponse(to: req)
            .assertStatus(is: .ok)
    }

    func testLogin_bad() throws {
        let req = try makeTestRequest(method: .post, path: "users/login")

        try drop
            .testResponse(to: req)
            .assertStatus(is: .badRequest)
    }

    func testLogin_success() throws {
        let username = "testuserslogin"
        let password = "testusersloginpassword"

        try User(username: username, password: try drop.hash.make(password).makeString()).save()

        let req = try makeTestRequest(method: .post, path: "users/login", json: JSON(node: ["loginName": username, "loginPassword": password]))

        try drop
            .testResponse(to: req)
            .assertStatus(is: .ok)
    }

    func testMe_bad() throws {
        try drop
            .testResponse(to: .get, at: "users/me")
            .assertStatus(is: .forbidden)
    }

    func testMe_success() throws {
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
        ("testCreate_bad", testCreate_bad),
        ("testCreate_success", testCreate_success),
        ("testLogin_bad", testLogin_bad),
        ("testLogin_success", testLogin_success),
        ("testMe_bad", testMe_bad),
        ("testMe_success", testMe_success)
    ]
}
