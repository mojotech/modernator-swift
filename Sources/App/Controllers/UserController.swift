import Vapor
import HTTP

/// Here we have a controller that helps facilitate the /user endpoint
final class UserController {
    // Create a new user
    func create(_ request: Request) throws -> ResponseRepresentable {
        let json = request.json!
        let user = User(username: try json.get("userName"), password: try json.get("userPassword"))
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

extension UserController: EmptyInitializable { }
