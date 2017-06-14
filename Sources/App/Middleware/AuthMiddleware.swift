import HTTP
import Authentication

/// Add this middleware to your server to
/// persist and fetch persisted models that
/// conform to the `Persistable` protocol.
public final class AuthMiddleware<U: Authenticatable>: Middleware {
    public init(_ userType: U.Type = U.self) {}

    public func respond(to req: Request, chainingTo next: Responder) throws -> Response {
        let _ = try req.auth.assertAuthenticated(U.self)

        return try next.respond(to: req)
    }
}
