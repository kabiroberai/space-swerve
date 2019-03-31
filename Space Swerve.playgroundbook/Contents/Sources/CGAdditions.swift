//
//  CGAdditions.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 20/03/19.
//

import Foundation
import CoreGraphics

// MARK:- CGRect Additions
extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

// MARK:- CGSize Additions
extension CGSize {
    func aspectScaled(to other: CGSize, fill: Bool) -> CGSize {
        let aspectRatio = width / height
        let otherAspectRatio = other.width / other.height
        let greaterWidth = (aspectRatio > otherAspectRatio)
        if greaterWidth == fill { // true if (greater width and fill), or (greater height and fit)
            return CGSize(width: other.height * aspectRatio,
                          height: other.height)
        } else {
            return CGSize(width: other.width,
                          height: other.width / aspectRatio)
        }
    }
}

public func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
}

public func /= (lhs: inout CGSize, rhs: CGFloat) {
    lhs = lhs / rhs
}

public func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
}

public func *= (lhs: inout CGSize, rhs: CGFloat) {
    lhs = lhs * rhs
}

// MARK:- CGPoint Additions
extension CGPoint {
    func squaredDistance(from other: CGPoint) -> CGFloat {
        return pow(x - other.x, 2) + pow(y - other.y, 2)
    }

    func distance(from other: CGPoint) -> CGFloat {
        return sqrt(squaredDistance(from: other))
    }
}

public func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

public func += (lhs: inout CGPoint, rhs: CGPoint) {
    lhs = lhs + rhs
}

public func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

public func -= (lhs: inout CGPoint, rhs: CGPoint) {
    lhs = lhs - rhs
}

public func * (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
}

public func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
}

public func *= (lhs: inout CGPoint, rhs: CGPoint) {
    lhs = lhs * rhs
}

public func *= (lhs: inout CGPoint, rhs: CGFloat) {
    lhs = lhs * rhs
}

public func / (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
}

public func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
}

public func /= (lhs: inout CGPoint, rhs: CGPoint) {
    lhs = lhs / rhs
}

public func /= (lhs: inout CGPoint, rhs: CGFloat) {
    lhs = lhs / rhs
}
