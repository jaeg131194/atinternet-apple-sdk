//
//  DictionaryExtension.swift
//  SmartTracker
//
//  Created by Théo Damaville on 05/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation

extension NSDictionary {
    
    /**
     Add a dictionary to a not nested existing key
    
     - parameter key:  an existing key not nested
     - parameter dict: a dictionary
     */
    func addDictionaryForKey(key: String, dict: NSDictionary) {
        let data = self.objectForKey(key)?.mutableCopy() as! NSMutableDictionary
        data.addEntriesFromDictionary(dict as [NSObject:AnyObject])
        self.setValue(data, forKey: key)
    }
    /**
     toJson: A method to get the JSON String representation of the dictionary
     
     - returns: the JSON String representation - An Empty String if it fails
     */
    func toJSON() -> String {
        if NSJSONSerialization.isValidJSONObject(self as AnyObject) {
            if let data = try?NSJSONSerialization.dataWithJSONObject(self as AnyObject, options: []) {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string as String
                }
            }
        }
        return ""
    }
}