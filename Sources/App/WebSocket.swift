import Vapor

extension WebSocket: Hashable {
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    public static func ==(lhs: WebSocket, rhs: WebSocket) -> Bool {
        return lhs === rhs
    }
}
