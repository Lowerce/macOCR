//
//  ScreenCapture.swift
//  ScreenCapture
//
//  Created by Jack P. on 11/12/2015.
//  Copyright © 2015 Jack P. All rights reserved.
//

import Foundation

// -------------------------------------------------------------------
// Allow passing of strings, just convert them to an NSURL.

public func captureRegion(destination: String) -> NSURL {
    return captureRegion(destination: NSURL(fileURLWithPath: destination))
}

public func captureScreen(destination: String) -> NSURL {
    return captureScreen(destination: NSURL(fileURLWithPath: destination))
}

public func recordScreen(destination: String) -> ScreenRecorder {
    return recordScreen(destination: NSURL(fileURLWithPath: destination))
}

// -------------------------------------------------------------------

public func captureRegion(destination: NSURL) -> NSURL {
    let destinationPath = destination.path! as String

    let task = Process()
    task.launchPath = "/usr/sbin/screencapture"
    task.arguments = ["-i", "-r", "-x", destinationPath]
    task.launch()
    task.waitUntilExit()

    return destination
}

public func captureRect(destination: String, x: Int, y: Int, width: Int, height: Int) -> NSURL {
    return captureRect(destination: NSURL(fileURLWithPath: destination), x: x, y: y, width: width, height: height)
}

public func captureRect(destination: NSURL, x: Int, y: Int, width: Int, height: Int) -> NSURL {
    let destinationPath = destination.path! as String
    let rectString = "\(x),\(y),\(width),\(height)"

    let task = Process()
    task.launchPath = "/usr/sbin/screencapture"
    task.arguments = ["-R", rectString, "-x", destinationPath]
    task.launch()
    task.waitUntilExit()

    return destination
}

public func captureScreen(destination: NSURL) -> NSURL {
    let img = CGDisplayCreateImage(CGMainDisplayID())
    let dest = CGImageDestinationCreateWithURL(destination, kUTTypePNG, 1, nil)
    CGImageDestinationAddImage(dest!, img!, nil)
    CGImageDestinationFinalize(dest!)
    
    return destination
}

public func recordScreen(destination: NSURL) -> ScreenRecorder {
    return ScreenRecorder(destination: destination)
}
