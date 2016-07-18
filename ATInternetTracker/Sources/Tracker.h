//
//  Tracker.h
//  Tracker
//
//  Created by Xavier BELLENGER on 12/07/2016.
//
//

#import <UIKit/UIKit.h>

//! Project version number for Tracker.
FOUNDATION_EXPORT double TrackerVersionNumber;

//! Project version string for Tracker.
FOUNDATION_EXPORT const unsigned char TrackerVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Tracker/PublicHeader.h>
#import "Crash.h"
#import "Hash.h"

#if TARGET_OS_IPHONE && defined(AT_SMART_TRACKER)

#import "JRSwizzle.h"
#import "ATGestureRecognizer.h"
#import "SRWebSocket.h"
#import "KLCPopup.h"

#endif