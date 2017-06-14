import Vapor
import AuthProvider

extension Droplet {
    func setupRoutes() throws {
        let persistMiddleware = PersistMiddleware(User.self)
        let authed = grouped(persistMiddleware)

        let userController = UserController(self.hash)
        post("users", handler: userController.create)
        post("users/login", handler: userController.login)
        authed.get("users/me", handler: userController.me)

        try authed.resource("sessions", SessionController.self)
    }
}
