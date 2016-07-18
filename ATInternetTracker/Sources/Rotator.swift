//
//  Rotator.swift
//  SmartTracker
//
//  Created by Théo Damaville on 23/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation

/// Helper class to handle rotations
class Rotator {
    /// the initial touch points
    var initialPoints: (CGPoint, CGPoint)
    
    /// the current touch points
    var currentPoints: (CGPoint, CGPoint)
    
    /// the initial rotation (~0)
    var initialRotation:CGFloat?
    
    /**
     Init method with the 2 initial touch location
     
     - parameter p1: p1
     - parameter p2: p2
     
     - returns: Rotator object
     */
    init(p1: CGPoint, p2: CGPoint) {
        initialPoints = (p1, p2)
        currentPoints = (p1, p2)
        initialRotation = nil
    }
    
    /**
     Set the current touch points
     
     - parameter p1: p1
     - parameter p2: p2
     */
    func setCurrentPoints(p1: CGPoint, p2: CGPoint) {
        currentPoints = (p1, p2)
        if initialRotation == nil {
            initialRotation = getCurrentRotation()
        }
    }
    
    /**
     get the current rotation between the initial and current lines formed by the 4 points
     
     - returns: the value between -180/180 degree
     */
    func getCurrentRotation() -> CGFloat {
        let angle = Maths.angleBetween(initialPoints.0, initialP2: initialPoints.1, finalP1: currentPoints.0, finalP2: currentPoints.1)
        if angle > 180 {
            return angle-360
        }
        return angle
    }
    
    /**
     check if the 2 lines (formed by the 2 points) are considered as a rotation
     
     - returns: true if we consider it as a rotation
     */
    func isValidRotation() -> Bool {
        if let _ = initialRotation {
            return (abs(initialRotation! - getCurrentRotation())) > 30 && (abs(initialRotation! - getCurrentRotation()) < 150)
        } else {
            return false
        }
    }
}