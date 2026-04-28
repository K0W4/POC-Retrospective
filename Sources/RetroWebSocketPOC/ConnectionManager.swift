//
//  ConnectionManager.swift
//  RetroWebSocketPOC
//
//  Created by Gabriel Kowaleski on 27/04/26.
//

import Vapor

actor ConnectionManager {
    // Estado em memória
    private var rooms: [String: [WebSocket]] = [:]
    private var discussions: [String: [Discussion]] = [:] // roomID -> Array de Discussões

    func createRoom() -> String {
        let roomID = UUID().uuidString
        rooms[roomID] = []
        discussions[roomID] = [] // Inicializa as discussões da sala
        print("Nova sala criada: \(roomID)")
        return roomID
    }

    func add(connection: WebSocket, toRoom roomID: String) {
        rooms[roomID, default: []].append(connection)
        print("Usuário entrou no board \(roomID). Total ativos: \(rooms[roomID]?.count ?? 0)")
    }

    func remove(connection: WebSocket, fromRoom roomID: String) {
        if var connections = rooms[roomID] {
            connections.removeAll(where: { $0 === connection })
            rooms[roomID] = connections
            print("Usuário saiu do board \(roomID). Restam: \(connections.count)")
        }
    }

    // Broadcast agora recebe um evento genérico e encoda para JSON
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
    
    // MARK: - Gerenciamento de Discussões
    
    func addDiscussion(_ discussion: Discussion, toRoom roomID: String) {
        discussions[roomID, default: []].append(discussion)
    }
    
    func vote(discussionID: UUID, roomID: String, userID: String) -> Discussion? {
        guard var roomDiscussions = discussions[roomID],
              let index = roomDiscussions.firstIndex(where: { $0.id == discussionID }) else {
            return nil
        }
        
        // Evita que o mesmo usuário vote várias vezes na mesma discussão
        if !roomDiscussions[index].votedBy.contains(userID) {
            roomDiscussions[index].votedBy.append(userID)
            discussions[roomID] = roomDiscussions // Atualiza o estado
        }
        
        return roomDiscussions[index]
    }
}
