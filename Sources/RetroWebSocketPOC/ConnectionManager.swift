//
//  ConnectionManager.swift
//  RetroWebSocketPOC
//

import Vapor

actor ConnectionManager {
    private var rooms: [String: [WebSocket]] = [:]
    private var discussions: [String: [Discussion]] = [:]
    
    struct RoomInfo: Content {
        let usersCount: Int
    }

    func createRoom() -> String {
        let roomID = UUID().uuidString
        rooms[roomID] = []
        discussions[roomID] = []
        print("Nova sala criada: \(roomID)")
        return roomID
    }

    func add(connection: WebSocket, toRoom roomID: String) {
        rooms[roomID, default: []].append(connection)
        
        let count = rooms[roomID]?.count ?? 0
        let event = WSEvent(type: "room:info", payload: RoomInfo(usersCount: count))
        broadcast(event, toRoom: roomID)
        
        if let roomDiscussions = discussions[roomID], !roomDiscussions.isEmpty {
            let historyEvent = WSEvent(type: "discussion:history", payload: roomDiscussions)
            do {
                let data = try JSONEncoder().encode(historyEvent)
                if let message = String(data: data, encoding: .utf8) {
                    connection.send(message)
                }
            } catch {
                print("Erro ao enviar histórico para usuário: \(error)")
            }
        }
    }

    func remove(connection: WebSocket, fromRoom roomID: String) {
        if var connections = rooms[roomID] {
            connections.removeAll(where: { $0 === connection })
            rooms[roomID] = connections
            
            let event = WSEvent(type: "room:info", payload: RoomInfo(usersCount: connections.count))
            broadcast(event, toRoom: roomID)
        }
    }

    func broadcast<T: Encodable>(_ event: WSEvent<T>, toRoom roomID: String) {
        guard let connections = rooms[roomID] else { return }
        
        do {
            let data = try JSONEncoder().encode(event)
            if let message = String(data: data, encoding: .utf8) {
                for connection in connections {
                    connection.send(message)
                }
            }
        } catch {
            print("Erro ao encodar evento WebSocket: \(error)")
        }
    }
    
    func addDiscussion(_ discussion: Discussion, toRoom roomID: String) {
        discussions[roomID, default: []].append(discussion)
    }
    
    func vote(discussionID: UUID, roomID: String, userID: String) -> Discussion? {
        guard var roomDiscussions = discussions[roomID],
              let index = roomDiscussions.firstIndex(where: { $0.id == discussionID }) else {
            return nil
        }
        
        if !roomDiscussions[index].votedBy.contains(userID) {
            roomDiscussions[index].votedBy.append(userID)
            discussions[roomID] = roomDiscussions
        }
        
        return roomDiscussions[index]
    }
}
