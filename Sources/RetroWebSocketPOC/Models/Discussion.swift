//
//  Discussion.swift
//  RetroWebSocketPOC
//
//  Created by Gabriel Kowaleski on 29/04/26.
//

import Vapor

struct Discussion: Content {
    let id: UUID
    var question: String
    var votedBy: [String]

    var votes: Int {
        votedBy.count
    }
    
    init(id: UUID = UUID(), question: String, votedBy: [String] = []) {
        self.id = id
        self.question = question
        self.votedBy = votedBy
    }
}
