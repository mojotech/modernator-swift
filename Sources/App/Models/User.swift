//
//  User.swift
//  modernator-swift-vapor
//

import Vapor
import FluentProvider

final class User: Model {
    let storage = Storage()

    var username: String
    var password: String

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    init(row: Row) throws {
        username = try row.get("username")
        password = try row.get("password")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("username", username)
        try row.set("password", password)
        return row
    }

}

extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("username")
            builder.string("password")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
