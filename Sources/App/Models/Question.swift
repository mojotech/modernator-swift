import Vapor
import FluentProvider

final class Question: Model {
    let storage = Storage()

    var sessionId: Identifier
    /// Who posted the question?
    var userId: Identifier
    var text: String
    var answered: Bool

    init(session: Session, user: User, text: String, answered: Bool) {
        self.sessionId = session.id!
        self.userId = user.id!
        self.text = text
        self.answered = answered
    }

    init(row: Row) throws {
        sessionId = try row.get(Session.foreignIdKey)
        userId = try row.get(User.foreignIdKey)
        text = try row.get("text")
        answered = try row.get("answered")
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Session.foreignIdKey, sessionId)
        try row.set(User.foreignIdKey, userId)
        try row.set("text", text)
        try row.set("answered", answered)
        return row
    }

}

// MARK: Relations

extension Question {
    var session: Parent<Question, Session> {
        return parent(id: sessionId)
    }
}

extension Question {
    var user: Parent<Question, User> {
        return parent(id: userId)
    }
}


// MARK: Schema

extension Question: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.foreignId(for: Session.self)
            builder.foreignId(for: User.self)
            builder.string("text")
            builder.bool("answered", default: false)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

// MARK: JSON

extension Question: JSONRepresentable {
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("questionId", id)
        try json.set("sessionId", session.parentId)
        try json.set("questionVotes", []) // TODO
        try json.set("questionText", text)
        try json.set("questionAnswered", answered)
        return json
    }
}
