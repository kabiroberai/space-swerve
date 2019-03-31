//
//  Extensions.swift
//  Book_Sources
//
//  Created by Kabir Oberai on 20/03/19.
//

import UIKit
import AVFoundation

func unimplemented(_ message: String? = nil,
                   function: StaticString = #function,
                   file: StaticString = #file,
                   line: UInt = #line) -> Never {
    var fullMessage = "\(function) has not been implemented"
    if let message = message {
        fullMessage += ". Message: \(message)"
    }
    fatalError(fullMessage, file: file, line: line)
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return max(range.lowerBound, min(range.upperBound, self))
    }
}

extension UIInterfaceOrientation {
    var avOrientation: AVCaptureVideoOrientation {
        let mapping: [UIInterfaceOrientation: AVCaptureVideoOrientation] = [
            .portrait: .portrait,
            .portraitUpsideDown: .portraitUpsideDown,
            .landscapeLeft: .landscapeLeft,
            .landscapeRight: .landscapeRight
        ]
        return mapping[self, default: .portrait]
    }
}
