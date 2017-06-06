import Vapor
import AuthProvider

extension Droplet {
    func setupRoutes() throws {
        get("hello") { req in
            var json = JSON()
            try json.set("hello", "world")
            return json
        }

        // response to requests to /info domain
        // with a description of the request
        get("info") { req in
            return req.description
        }

        get("description") { req in return req.description }
        
//        try resource("posts", PostController.self)


        let persistMiddleware = PersistMiddleware(User.self)
        let authed = grouped(persistMiddleware)

        let userController = UserController()
        post("users", handler: userController.create)
        post("users/login", handler: userController.login)
        authed.get("users/me", handler: userController.me)
    }
}
