//
//  Maths.swift
//  SmartTracker
//
//  Created by Théo Damaville on 10/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation
import CoreGraphics

/// Basic Maths operations
class Maths {
    static let PI = CGFloat(M_PI)
    
    /**
     Substract 2 CGPoints
     
     - parameter a: point a
     - parameter b: point b
     
     - returns: a-b
     */
    class func CGPointSub(a: CGPoint, b: CGPoint) -> CGPoint {
        return CGPointMake(a.x-b.x, a.y-b.y)
    }
    
    /**
     Distance between 2 CGPoints
     
     - parameter a: point a
     - parameter b: point b
     
     - returns: the distance
     */
    class func CGPointDist(a: CGPoint, b:CGPoint) -> CGFloat {
        return sqrt(  (b.x-a.x)*(b.x-a.x) + (b.y-a.y)*(b.y-a.y) )
    }
    
    /**
     helper method for distance between 2 points
     
     - parameter a: a point
     
     - returns: ??
     */
    class func CGPointLen(a: CGPoint) -> Float {
        return sqrtf(Float(a.x*a.x+a.y*a.y))
    }
    
    /**
     Angle between 2 lines (defined by 4 points)
     
     - parameter initialP1: Line1.p1
     - parameter initialP2: Line1.p2
     - parameter finalP1:   Line2.p1
     - parameter finalP2:   Line2.p2
     
     - returns: the angle between the 2 lines in degree 0-360
     */
    class func angleBetween(initialP1: CGPoint, initialP2: CGPoint, finalP1: CGPoint, finalP2: CGPoint) -> CGFloat {
        let vector1 = (initialP1.x - initialP2.x, initialP1.y - initialP2.y)
        let vector2 = (finalP1.x - finalP2.x, finalP1.y - finalP2.y)
        var angle = atan2(vector2.1, vector2.0) - atan2(vector1.1, vector1.0);
        if angle < 0 {
            angle += 2 * PI;
        }
        return angle*180/PI

    }
}