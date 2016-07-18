//
//  Toolbox.swift
//  SmartTracker
//
//  Created by Théo Damaville on 04/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation

extension NSObject {
    
    /// Allow to get the Class name of an object
    /// Swift equivalent of NSStringFromClass([self class])
    var classLabel: String {
        let str =  NSStringFromClass(self.classForCoder)
        
        if let name = str.componentsSeparatedByString(".").last {
            return name
        }
        
        return ""
    }
    
    /**
     Check if a property is present in the object using reflexion
     
     - parameter property: the property to check the existence
     
     - returns: true is the property is present in the object
     */
    func at_hasProperty(property: String) -> Bool {
        let cp = class_getProperty(object_getClass(self), property)
        if cp != nil {
            if let _ = self.valueForKey(property) {
                return true
            }
        }
        return false
    }
}