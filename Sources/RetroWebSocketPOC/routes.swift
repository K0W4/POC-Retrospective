import Vapor

func routes(_ app: Application) throws {
    let sharedConnectionManager = ConnectionManager()
    
    try app.register(collection: BoardController(connectionManager: sharedConnectionManager))
}
