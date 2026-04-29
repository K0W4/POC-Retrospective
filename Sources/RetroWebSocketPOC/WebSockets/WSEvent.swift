//
//  WSEvent.swift
//  RetroWebSocketPOC
//
//  Created by Gabriel Kowaleski on 29/04/26.
//

import Vapor

struct WSEvent<Payload: Content>: Content {
    let type: String
    let payload: Payload
}
