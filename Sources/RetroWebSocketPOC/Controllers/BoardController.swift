//
//  RoomController.swift
//  RetroWebSocketPOC
//
//  Created by Gabriel Kowaleski on 28/04/26.
//

import Vapor

struct BoardController: RouteCollection {
    
    let connectionManager: ConnectionManager
    
    func boot(routes: any RoutesBuilder) throws {
        let board = routes.grouped("board")
        
        // POST /board -> Cria a sala
        board.post(use: self.createRoom)
        
        // WS /board/:roomID -> Conecta na sala
        board.webSocket(":roomID", onUpgrade: self.connectWebSocket)
        
        // POST /board/votes -> Cria a discussão
        board.post("votes", use: self.createDiscussion)
        
        // POST /board/votes/:discussionID -> Adiciona o voto
        board.post("votes", ":discussionID", use: self.voteDiscussion)
    }
    
    @Sendable
    func createRoom(req: Request) async throws -> RoomResponseDTO {
        let roomID = await connectionManager.createRoom()
        
        // Tenta encontrar o IP local para facilitar o log
        let localIP = "Verifique o IP do seu Mac em Ajustes de Rede"
        print("-----------------------------------------")
        print("🚀 Sala Criada: \(roomID)")
        print("-----------------------------------------")
        
        return RoomResponseDTO(roomID: roomID)
    }
    
    @Sendable
    func connectWebSocket(req: Request, ws: WebSocket) {
        guard let roomID = req.parameters.get("roomID") else {
            _ = ws.close()
            return
        }

        Task {
            await connectionManager.add(connection: ws, toRoom: roomID)
        }

        ws.onClose.whenComplete { _ in
            Task {
                await connectionManager.remove(connection: ws, fromRoom: roomID)
            }
        }
    }
    
    @Sendable
    func createDiscussion(req: Request) async throws -> Response {
        let payload = try req.content.decode(CreateDiscussionDTO.self)
        let discussion = Discussion(question: payload.question)
        
        await connectionManager.addDiscussion(discussion, toRoom: payload.roomID)
        
        let event = WSEvent(type: "discussion:created", payload: discussion)
        await connectionManager.broadcast(event, toRoom: payload.roomID)
        
        
        return try await discussion.encodeResponse(status: .created, for: req)
    }
    
    @Sendable
    func voteDiscussion(req: Request) async throws -> Response {
        guard let discussionIDString = req.parameters.get("discussionID"),
              let discussionID = UUID(uuidString: discussionIDString) else {
            throw Abort(.badRequest, reason: "ID da discussão inválido.")
        }
        
        let payload = try req.content.decode(VoteDTO.self)
        
        guard let updatedDiscussion = await connectionManager.vote(
            discussionID: discussionID,
            roomID: payload.roomID,
            userID: payload.userID
        ) else {
            throw Abort(.notFound, reason: "Discussão ou sala não encontrada.")
        }
        
        let event = WSEvent(type: "discussion:voted", payload: updatedDiscussion)
        await connectionManager.broadcast(event, toRoom: payload.roomID)
        
        return try await updatedDiscussion.encodeResponse(status: .ok, for: req)
    }
}
