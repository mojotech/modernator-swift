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

        // auto login on create
        try user.persist(for: req)

        return Response(status: .ok)
    }

    // Authenticate
    func login(req: Request) throws -> ResponseRepresentable {
        guard let json = req.json else {
            throw Abort(.badRequest)
        }

        guard let username = json["loginName"]?.string else {
            throw Abort(.badRequest)
        }
        guard let password = json["loginPassword"]?.string else {
            throw Abort(.badRequest)
        }

        let passwordHash = try hash.make(password.makeBytes()).makeString()

        guard let match = try User.makeQuery()
            .filter("username", username)
            .filter("password", passwordHash)
            .first()
            else {
                throw Abort(.unauthorized)
        }

        req.auth.authenticate(match)
        try match.persist(for: req)

        return try me(req: req)
    }

    // Get currently authenticated user
    func me(req: Request) throws -> ResponseRepresentable {
        return try req.user().makeJSON()
    }
}
