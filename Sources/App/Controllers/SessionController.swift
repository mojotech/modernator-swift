import Vapor
import HTTP
import Console

enum MessageTag: String {
    case SessionState, SessionLocked, SessionExpired, SessionClosed, SessionExceptionMessage
    case QuestionAsked, QuestionUpvoted, QuestionAnswered
    case QuestionerJoined
}

extension MessageTag {
    var key: String {
        if rawValue.hasPrefix("Session") {
            return "session"
        } else if rawValue.hasPrefix("Questioner") {
            return "questioner"
        } else if rawValue.hasPrefix("Question") {
            return "question"
        }
        return "unknown"
    }
}

/// Here we have a controller that helps facilitate the /sessions endpoint
final class SessionController: ResourceRepresentable {

    let console: ConsoleProtocol
    var websockets = [Int : Set<WebSocket>]()

    init(_ console: ConsoleProtocol) {
        self.console = console
    }

    func index(req: Request) throws -> ResponseRepresentable {
        return try Session.all().makeJSON()
    }

    func create(req: Request) throws -> ResponseRepresentable {
        guard let json = req.json else {
            throw Abort(.badRequest)
        }

        guard let name = json["sessionName"]?.string else {
            throw Abort(.badRequest)
        }

        let session = Session(answerer: req.user(), name: name, locked: false)
        try session.save()
        return try session.makeJSONSimple()
    }

    func show(req: Request, session: Session) throws -> ResponseRepresentable {
        return try session.makeJSON()
    }

    func lock(req: Request) throws -> ResponseRepresentable {
        let sessionId = try req.parameters.next(Int.self)
        guard let session = try Session.find(sessionId) else {
            throw Abort(.notFound)
        }

        guard session.answererId == req.user().id else {
            throw Abort(.unauthorized)
        }

        session.locked = true
        try session.save()

        try sendMessage(session: session, tag: .SessionLocked, data: session.makeJSON())

        return Response(status: .ok)
    }

    func join(req: Request) throws -> ResponseRepresentable {
        let sessionId = try req.parameters.next(Int.self)
        guard let session = try Session.find(sessionId) else {
            throw Abort(.notFound)
        }

        let user = req.user()
        // prevent duplicate pivot entries
        if !(try session.questioners.isAttached(user)) {
            try session.questioners.add(user)

            // custom minimal object for QuestionerJoined
            var messageData = JSON()
            try messageData.set("id", user.id)
            try messageData.set("name", user.username)
            try sendMessage(session: session, tag: .QuestionerJoined, data: messageData)
        }

        return try user.makeJSON()
    }

    func questionAsk(req: Request) throws -> ResponseRepresentable {
        let sessionId = try req.parameters.next(Int.self)
        guard let session = try Session.find(sessionId) else {
            throw Abort(.notFound)
        }

        guard let json = req.json else {
            throw Abort(.badRequest)
        }

        guard let text = json["question"]?.string else {
            throw Abort(.badRequest)
        }

        let question = Question(session: session, user: req.user(), text: text, answered: false)
        try question.save()

        try sendMessage(session: session, tag: .QuestionAsked, data: question.makeJSON())

        return try question.makeJSON()
    }

    func questionUpvote(req: Request) throws -> ResponseRepresentable {
        let sessionId = try req.parameters.next(Int.self)
        guard let session = try Session.find(sessionId) else {
            throw Abort(.notFound)
        }

        let questionId = try req.parameters.next(Int.self)
        guard let question = try session.questions.find(questionId) else {
            throw Abort(.notFound)
        }

        // prevent double-voting
        if ((try question.votes.filter(User.foreignIdKey, req.user().id).first()) == nil) {
            let vote = Vote(question: question, user: req.user())
            try vote.save()

            try sendMessage(session: session, tag: .QuestionUpvoted, data: question.makeJSON())
        }

        return try question.makeJSON()
    }

    func questionAnswer(req: Request) throws -> ResponseRepresentable {
        let sessionId = try req.parameters.next(Int.self)
        guard let session = try Session.find(sessionId) else {
            throw Abort(.notFound)
        }

        let questionId = try req.parameters.next(Int.self)
        guard let question = try session.questions.find(questionId) else {
            throw Abort(.notFound)
        }

        question.answered = true
        try question.save()

        try sendMessage(session: session, tag: .QuestionAnswered, data: question.makeJSON())

        return try question.makeJSON()
    }

    // Non-websocket endpoint for messages
    func messages(req: Request) throws -> ResponseRepresentable {
        let sessionId = try req.parameters.next(Int.self)
        guard let session = try Session.find(sessionId) else {
            throw Abort(.notFound)
        }

        return try show(req: req, session: session)
    }

    func messagesSocket(req: Request, ws: WebSocket) throws {

        let sessionId = try req.parameters.next(Int.self)
        guard let session = try Session.find(sessionId) else {
            throw Abort(.notFound)
        }

        var json = JSON()
        try json.set("tag", "SessionState")
        try json.set("session", session)

        try ws.send(json.makeBytes().makeString())

        if (websockets[sessionId] == nil) {
            websockets[sessionId] = Set<WebSocket>()
        }
        websockets[sessionId]!.insert(ws)


        background {
            while ws.state == .open {
                try? ws.ping()
                self.console.wait(seconds: 10)
            }
        }

        ws.onClose = { ws, code, reason, clean in
            self.websockets[sessionId]!.remove(ws)
        }
    }

    func sendMessage(session: Session, tag: MessageTag, data: JSON) throws {
        var json = JSON()
        try json.set("tag", tag.rawValue)
        try json.set(tag.key, data)

        try websockets[session.id!.int!]?.forEach { ws in
            try ws.send(json.makeBytes().makeString())
        }
    }

    func makeResource() -> Resource<Session> {
        return Resource(
            index: index,
            store: create,
            show: show,
            update: nil,
            replace: nil,
            destroy: nil, // delete
            clear: nil
        )
    }

}
