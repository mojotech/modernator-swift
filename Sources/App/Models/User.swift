import Vapor
import FluentProvider
import AuthProvider

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

// MARK: Relations

extension User {
    var answererSessions: Children<User, Session> {
        return children()
    }
}

// MARK: Schema

extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("username", unique: true)
            builder.string("password")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

// MARK: Auth

extension User: Authenticatable {}
extension User: SessionPersistable {}

extension Request {
    func user() -> User {
        return auth.authenticated()!
    }
}
