//
//  FaceTracker+Configuration.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 20/03/19.
//

import Foundation
import PlaygroundSupport

extension FaceTracker {
    public struct Configuration: PlaygroundValueConvertible {
        public let retrackPeriodically: Bool
        public let applyLowPassFilter: Bool
        public let detectLandmarks: Bool

        /// Create a new FaceTracker configuration
        ///
        /// - Parameter accurateTrackInterval: The interval after which the bufferer does an accurate face
        /// track (rather than a simple object track). A value of zero means that the bufferer will track
        /// the user's face continuously.
        ///
        /// - Parameter landmarkTrackInterval: The interval after which facial landmarks are re-scanned.
        /// A value of zero means that the bufferer will scan the user's facial landmarks continuously.
        ///
        /// - Parameter lowPassResistance: The amount by which the bounding box resists changes
        ///
        /// - Parameter minimumConfidence: The minimum confidence level required for an observation.
        /// If this is not met then the observation is discarded.
        public init(
            retrackPeriodically: Bool = true,
            applyLowPassFilter: Bool = false,
            detectLandmarks: Bool = true
        ) {
            self.retrackPeriodically = retrackPeriodically
            self.applyLowPassFilter = applyLowPassFilter
            self.detectLandmarks = detectLandmarks
        }

        public init?(value: PlaygroundValue) {
            if case let .dictionary(dict) = value,
                case let .boolean(retrackPeriodically)? = dict["retrackPeriodically"],
                case let .boolean(applyLowPassFilter)? = dict["applyLowPassFilter"],
                case let .boolean(detectLandmarks)? = dict["detectLandmarks"] {
                self.retrackPeriodically = retrackPeriodically
                self.applyLowPassFilter = applyLowPassFilter
                self.detectLandmarks = detectLandmarks
            } else {
                return nil
            }
        }

        public func encode() -> PlaygroundValue {
            return .dictionary([
                "retrackPeriodically": .boolean(retrackPeriodically),
                "applyLowPassFilter": .boolean(applyLowPassFilter),
                "detectLandmarks": .boolean(detectLandmarks)
            ])
        }
    }
}
