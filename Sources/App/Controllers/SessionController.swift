import Vapor
import HTTP

/// Here we have a controller that helps facilitate the /sessions endpoint
final class SessionController: ResourceRepresentable, EmptyInitializable {

    var websockets = Set<WebSocket>()

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
        return try session.makeJSON()
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

        try ws.send(json.makeBytes())

        websockets.insert(ws)

        ws.onClose = { ws, code, reason, clean in
            self.websockets.remove(ws)
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
