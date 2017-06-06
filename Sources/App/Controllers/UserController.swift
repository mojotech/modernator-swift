import Vapor
import HTTP

/// Here we have a controller that helps facilitate the /user endpoint
final class UserController {

    let hash: HashProtocol

    init(_ hash: HashProtocol) {
        self.hash = hash
    }

    // Create a new user
    func create(_ request: Request) throws -> ResponseRepresentable {
        guard let json = request.json else {
            throw Abort(.badRequest)
        }

        guard let username = json["userName"]?.string else {
            throw Abort(.badRequest)
        }
        guard let password = json["userPassword"]?.string else {
            throw Abort(.badRequest)
        }

        // TODO: better error message if username already exists

        let user = User(
            username: username,
            password: try hash.make(password.makeBytes()).makeString()
        )
        try user.save()
        return Response(status: .ok)
    }

    // Authenticate
    func login(_ request: Request) throws -> ResponseRepresentable {
        return "login"
    }

    // Get currently authenticated user
    func me(_ request: Request) throws -> ResponseRepresentable {
        var json = JSON()
        let user = try request.user()
        try json.set("userId", user.id)
        try json.set("userName", user.username)
        // TODO answererSessions
        // TODO questionerSessions
        return json
    }
}
