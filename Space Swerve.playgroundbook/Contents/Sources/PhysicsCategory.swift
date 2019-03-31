//
//  PhysicsCategory.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 22/03/19.
//

import SpriteKit

// automatic OptionSet dance inspired by my 2017 playground submission

struct PhysicsCategory: OptionSet {
    var rawValue: UInt32
    fileprivate static var current: UInt32 = 1
    static let none = PhysicsCategory(rawValue: .min)
    static let all = PhysicsCategory(rawValue: .max)
}

fileprivate extension PhysicsCategory {
    static func next() -> PhysicsCategory {
        defer { PhysicsCategory.current *= 2 }
        return PhysicsCategory(rawValue: PhysicsCategory.current)
    }
}

extension PhysicsCategory {
    static let scene = PhysicsCategory.next()
    static let asteroid = PhysicsCategory.next()
    static let ufo = PhysicsCategory.next()
    static let enemy = PhysicsCategory.next()
    static let laser = PhysicsCategory.next()
    static let charge = PhysicsCategory.next()
}

extension SKPhysicsBody {
    var fieldCategory: PhysicsCategory {
        get { return PhysicsCategory(rawValue: fieldBitMask) }
        set { fieldBitMask = newValue.rawValue }
    }

    var category: PhysicsCategory {
        get { return PhysicsCategory(rawValue: categoryBitMask) }
        set { categoryBitMask = newValue.rawValue }
    }

    var collisionCategory: PhysicsCategory {
        get { return PhysicsCategory(rawValue: collisionBitMask) }
        set { collisionBitMask = newValue.rawValue }
    }

    var contactTestCategory: PhysicsCategory {
        get { return PhysicsCategory(rawValue: contactTestBitMask) }
        set { contactTestBitMask = newValue.rawValue }
    }
}
