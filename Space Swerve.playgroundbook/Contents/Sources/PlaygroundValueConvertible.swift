//
//  PlaygroundValueConvertible.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 23/03/19.
//

import Foundation
import PlaygroundSupport

public protocol PlaygroundValueConvertible {
    init?(value: PlaygroundValue)
    func encode() -> PlaygroundValue
}

public extension PlaygroundLiveViewMessageHandler {
    func send(_ message: PlaygroundValueConvertible) {
        send(message.encode())
    }
}
