import Vapor
import HTTP
import Console

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
