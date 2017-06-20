import Vapor
import FluentProvider

final class Vote: Model {
    let storage = Storage()

    var questionId: Identifier
    var userId: Identifier

    init(question: Question, user: User) {
        self.questionId = question.id!
        self.userId = user.id!
    }

    init(row: Row) throws {
        questionId = try row.get(Question.foreignIdKey)
        userId = try row.get(User.foreignIdKey)
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Question.foreignIdKey, questionId)
        try row.set(User.foreignIdKey, userId)
        return row
    }

}

// MARK: Relations

extension Vote {
    var question: Parent<Vote, Question> {
        return parent(id: questionId)
    }
}

extension Vote {
    var user: Parent<Vote, User> {
        return parent(id: userId)
    }
}


// MARK: Schema

extension Vote: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.foreignId(for: Question.self)
            builder.foreignId(for: User.self)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
