import Vapor
import AuthProvider

extension Droplet {
    func setupRoutes() throws {
        let persistMiddleware = PersistMiddleware(User.self)
        let global = grouped(persistMiddleware)

        let authMiddleware = AuthMiddleware(User.self)
        let authed = global.grouped(authMiddleware)

        let userController = UserController(self.hash)
        global.post("users", handler: userController.create)
        global.post("users/login", handler: userController.login)
        authed.get("users/me", handler: userController.me)

        let sessionController = SessionController()
        authed.resource("sessions", sessionController)
        authed.post("sessions", Int.parameter, "lock", handler: sessionController.lock)

        authed.post("sessions", Int.parameter, "join", handler: sessionController.join)

        authed.get("sessions", Int.parameter, "messages", handler: sessionController.messages)
        authed.socket("sessions", Int.parameter, "messages", handler: sessionController.messagesSocket)
    }
}
