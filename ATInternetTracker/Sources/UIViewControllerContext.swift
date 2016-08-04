//
//  UIViewControllerContext.swift
//  SmartTracker
//
//  Created by Théo Damaville on 04/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation
import UIKit



/// Singleton managing the displayed UIViewController events
class UIViewControllerContext {
    
    enum UIViewControllerOrientation: Int {
        case Portrait = 1
        case Landscape = 2
    }
    
    /// A Stack of UIVIewController displayed
    lazy var activeViewControllers = [UIViewController]()
    
    /// Get the viewController currently displayed
    var currentViewController: UIViewController? {
        return activeViewControllers.last
    }
    
    lazy var currentOrientation: UIViewControllerOrientation = UIViewControllerOrientation.Portrait
    var isPeekAndPoped: Bool = false
    var isPeek: Bool = false
        
    
    /// A timestamp representing the time where the last view was loaded
    lazy var viewAppearedTime = NSDate().timeIntervalSinceNow
    
    /// An array representing "noise" viewcontrollers that are loaded quietly that we want to ignore
    let UIClassToIgnore = [
        NSClassFromString("UICompatibilityInputViewController"),
        NSClassFromString("UIInputWindowController"),
        NSClassFromString("UIKeyboardCandidateGridCollectionViewController"),
        NSClassFromString("UIApplicationRotationFollowingControllerNoTouches"),
        NSClassFromString("UINavigationController"),
        NSClassFromString("MKSmallCalloutViewController"),
        NSClassFromString("UIPageViewController"),
        NSClassFromString("UIApplicationRotationFollowingController"),
    ];
    
    /// An array representing "noise" protocols that are loaded quietly that we want to ignore
    let UIProtocolToIgnore = [
        NSProtocolFromString("UIPageViewControllerDelegate"),
        NSProtocolFromString("UIPageViewControllerDataSource"),
    ];
    
    /// Singleton
    static let sharedInstance = UIViewControllerContext()
    
    private init() { }
}
