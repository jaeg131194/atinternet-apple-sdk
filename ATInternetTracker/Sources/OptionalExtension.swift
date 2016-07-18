//
//  OptionalExtension.swift
//  Tracker
//
//  Created by Théo Damaville on 14/06/2016.
//  Copyright © 2016 AT Internet. All rights reserved.
//

import Foundation

extension Optional {
    func getOrElse(defaultValue: Wrapped) -> Wrapped {
        if self == nil {
            return defaultValue
        } else {
            return self!
        }
    }
}