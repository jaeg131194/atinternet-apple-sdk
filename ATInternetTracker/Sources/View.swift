//
//  View.swift
//  SmartTracker
//
//  Created by Nicolas Sagnette on 06/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation

/// Class representing the view that was touched by a user
public class View: NSObject {
    
    /// The subclass name of the touched UIView
    public var className: String
    
    /// X coordinates
    public var x: Float
    
    /// Y coordinates
    public var y: Float
    
    /// View width
    public var width: Float
    
    /// View height
    public var height: Float
    
    /// Text in view
    public var text: String
    
    /// Visibility of the view 
    public var visible: Bool
    
    /// position of the element in a list, tabbar...
    public var position:Int = -1
    
    /// Screenshot encoded in base64
    lazy var screenshot: String = ""
    
    /// Path to the view
    lazy var path: String = ""
    
    /// JSON description
    public override var description: String {
        return toJSONObject.toJSON()
    }
    
    var toJSONObject: NSDictionary {
        let jsonObj: NSDictionary = [
            "view":[
                "className": self.className,
                "x": self.x,
                "y": self.y,
                "width": self.width,
                "height": self.height,
                "text": self.text,
                "path": self.path,
                "screenshot": self.screenshot,
                "visible": self.visible,
                "position": self.position
            ]
        ]
        return jsonObj
    }
    
    /**
     Default init
     */
    override convenience init() {
        self.init(view: UIApplicationContext.sharedInstance.currentTouchedView)
    }
    
    /**
     Init with a uiview
     - parameter view: the uiview that going to be associated with the View
     */
    init(view: UIView?) {
        if let v = view {
            self.className = v.classLabel
            let newFrame = v.convertRect(v.bounds, toView: nil)
            self.x = Float(newFrame.origin.x)
            self.y = Float(newFrame.origin.y)
            self.width = Float(newFrame.width)
            self.height = Float(newFrame.height)
            self.text = v.findText(UIApplicationContext.sharedInstance.initialTouchPosition) ?? ""
            self.visible = (v.hidden || v.alpha == 0)
            
            super.init()
            
            self.path = v.path
        } else {
            self.className = ""
            self.x = 0
            self.y = 0
            self.width = 0
            self.height = 0
            self.text = ""
            self.visible = true
            
            super.init()
        }
    }
}
