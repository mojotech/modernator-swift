import Vapor
import HTTP

/// Here we have a controller that helps facilitate the /users endpoint
final class UserController {

    let hash: HashProtocol

    init(_ hash: HashProtocol) {
        self.hash = hash
    }

    // Create a new user
    func create(req: Request) throws -> ResponseRepresentable {
        guard let json = req.json else {
            throw Abort(.badRequest)
        }

        guard let username = json["userName"]?.string else {
            throw Abort(.badRequest)
        }
        guard let password = json["userPassword"]?.string else {
            throw Abort(.badRequest)
        }

        // TODO: better error message if username already exists
        // (keep in mind this is handled right now by a 'unique' constraint
        // in the table schema)

        let user = User(
            username: username,
            password: try hash.make(password.makeBytes()).makeString()
        )
        try user.save()
        return Response(status: .ok)
    }

    // Authenticate
    func login(req: Request) throws -> ResponseRepresentable {
        return "login"
    }

    // Get currently authenticated user
    func me(req: Request) throws -> ResponseRepresentable {
        var json = JSON()
        let user = try req.user()
        try json.set("userId", user.id)
        try json.set("userName", user.username)
        // TODO answererSessions
        // TODO questionerSessions
        return json
    }
}
