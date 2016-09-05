//
//  File.swift
//  ATInternetTracker
//
//  Created by Team Tag on 31/08/2016.
//
//

import Foundation

extension Dictionary {
    mutating func append<K, V>(_ dictionaries: Dictionary<K, V>...) {
        for dict in dictionaries {
            for(key, value) in dict {
                self.updateValue(value as! Value, forKey: key as! Key)
            }
        }
    }
    
    /**
    toJson: A method to get the JSON String representation of the dictionary
    
    - returns: the JSON String representation - An Empty String if it fails
    */
    func toJSON() -> String {
        if JSONSerialization.isValidJSONObject(self) {
            if let data = try?JSONSerialization.data(withJSONObject: self, options: []) {
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    return string as String
                }
            }
        }
        return ""
    }
}
