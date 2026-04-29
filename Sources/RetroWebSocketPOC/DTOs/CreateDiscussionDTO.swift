//
//  a.swift
//  RetroWebSocketPOC
//
//  Created by Gabriel Kowaleski on 29/04/26.
//

import Vapor

struct CreateDiscussionDTO: Content {
    let roomID: String
    let question: String
}
