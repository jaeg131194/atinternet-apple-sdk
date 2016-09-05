//
//  RotationOperation.swift
//  SmartTracker
//
//  Created by Théo Damaville on 05/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import UIKit
import Foundation

/// Class for sending gesture event to the socket server
class ScreenRotationOperation: Operation {
    
    /// The screen event to be sent
    var rotationEvent: ScreenRotationEvent
    
    /**
     RotationOperation init
     
     - parameter rotationEvent: rotationEvent
     
     - returns: RotationOperation
     */
    init(rotationEvent: ScreenRotationEvent) {
        self.rotationEvent = rotationEvent
    }
    
    override func main() {
        autoreleasepool {
            // Wait a little in order to make this operation cancellable
            Thread.sleep(forTimeInterval: 0.2)
            if !self.isCancelled {
                //TODO: sendBuffer
                ATInternet.sharedInstance.defaultTracker.socketSender!.sendMessage(rotationEvent.description)
            }
        }
    }
}
