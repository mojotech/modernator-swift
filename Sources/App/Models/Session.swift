import Vapor
import FluentProvider

final class Session: Model {
    let storage = Storage()

    var answererId: Identifier
    var name: String
    var locked: Bool

    init(answerer: User, name: String, locked: Bool) {
        self.answererId = answerer.id!
        self.name = name
        self.locked = locked
    }

    init(row: Row) throws {
        answererId = try row.get(User.foreignIdKey)
        name = try row.get("name")
        locked = try row.get("locked")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set(User.foreignIdKey, answererId)
        try row.set("name", name)
        try row.set("locked", locked)
        return row
    }

}

// MARK: Relations

extension Session {
    var answerer: Parent<Session, User> {
        return parent(id: answererId)
    }
}

extension Session {
    var questioners: Siblings<Session, User, Pivot<Session, User>> {
        return siblings()
    }
}

// MARK: Schema

extension Session: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.foreignId(for: User.self)
            builder.string("name")
            builder.bool("locked", default: false)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

// MARK: JSON

extension Session: JSONRepresentable {
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("session", try makeJSONSimple())
        try json.set("answerer", answerer.get())
        try json.set("questioners", questioners.all())
        // TODO:
        try json.set("questions", [])
        return json
    }
    func makeJSONSimple() throws -> JSON {
        var json = JSON()
        try json.set("sessionId", id)
        try json.set("name", name)
        try json.set("locked", locked ? "Locked" : "Unlocked")
        return json
    }
}
