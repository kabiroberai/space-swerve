//
//  Difficulty.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 23/03/19.
//

import SpriteKit
import PlaygroundSupport

public enum Difficulty: Int, PlaygroundValueConvertible {
    case easy
    case medium
    case hard

    public static let `default`: Difficulty = .medium

    public init?(value: PlaygroundValue) {
        guard case let .integer(rawValue) = value else { return nil }
        self.init(rawValue: rawValue)
    }

    public func encode() -> PlaygroundValue {
        return .integer(rawValue)
    }

    public private(set) static var completedDifficulties: Set<Difficulty> {
        get {
            guard let difficultiesValue = PlaygroundKeyValueStore.current["difficulties"],
                case let .array(difficulties) = difficultiesValue
                else { return [] }
            return Set(difficulties.compactMap(Difficulty.init))
        }
        set {
            PlaygroundKeyValueStore.current["difficulties"] = .array(newValue.map { $0.encode() })
        }
    }

    func setCompleted() {
        Difficulty.completedDifficulties.insert(self)
    }

    var displayText: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var baselineScore: Int {
        switch self {
        case .easy: return 300
        case .medium: return 250
        case .hard: return 200
        }
    }

    var asteroidSpawnPeriod: TimeInterval {
        switch self {
        case .easy: return 2
        case .medium: return 1.3
        case .hard: return 0.8
        }
    }

    var asteroidVelocity: TimeInterval {
        switch self {
        case .easy: return 5
        case .medium: return 9
        case .hard: return 12
        }
    }

    var enemySpawnPeriod: TimeInterval {
        switch self {
        case .easy: return 14
        case .medium: return 12
        case .hard: return 8
        }
    }

    var laserCount: Int {
        switch self {
        case .easy: return 5
        case .medium: return 7
        case .hard: return 10
        }
    }

    var laserBlastPeriod: TimeInterval {
        switch self {
        case .easy: return 1.3
        case .medium: return 1
        case .hard: return 0.8
        }
    }

    var chargeSpawnPeriod: TimeInterval {
        switch self {
        case .easy: return 5
        case .medium: return 7
        case .hard: return 9
        }
    }

    var ufoChargeRadiusMultiplier: CGFloat {
        switch self {
        case .easy: return 7
        case .medium: return 6
        case .hard: return 5
        }
    }

    var ufoChargeStrength: Float {
        switch self {
        case .easy: return 20
        case .medium: return 15
        case .hard: return 10
        }
    }
}

extension SKNode {
    // only works when the node is part of a `GameScene`
    var gameDifficulty: Difficulty {
        return (scene as? GameScene)?.difficulty ?? .default
    }
}
