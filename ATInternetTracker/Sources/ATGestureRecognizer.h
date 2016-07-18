//
//  ATGestureRecognizer.h
//  SmartTracker
//
//  Created by Théo Damaville on 12/11/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ATGestureRecognizer : NSObject

/**
 *  Get the recognizer from the touch event
 *
 *  @param touches   the touch event
 *  @param eventType the expected type
 *
 *  @return a dictionary with the recognizer infos
 */
+ (NSDictionary *) getRecognizerInfo:(NSSet <UITouch *> *)touches eventType:(NSString *)eventType;

/**
 *  try get the recognizer from an uiview
 *
 *  @param touchedView the view we want to get the recognizers
 *  @param eventType the expected event type for filter purpose
 *
 *  @return the infos about the recognizers
 */
+ (NSDictionary *)getRecognizerInfoFromView:(UIView *)touchedView withExpected:(NSString *)eventType;

@end
