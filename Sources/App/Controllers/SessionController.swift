import Vapor
import HTTP

/// Here we have a controller that helps facilitate the /sessions endpoint
final class SessionController: ResourceRepresentable, EmptyInitializable {

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

    func lock(req: Request) throws -> ResponseRepresentable {
        let sessionId = try req.parameters.next(Int.self)
        guard let session = try Session.find(sessionId) else {
            throw Abort(.notFound)
        }

        session.locked = true
        try session.save()

        return Response(status: .ok)
    }

    func makeResource() -> Resource<Session> {
        return Resource(
            index: index,
            store: create,
            show: nil,
            update: nil,
            replace: nil,
            destroy: nil, // delete
            clear: nil
        )
    }

}
