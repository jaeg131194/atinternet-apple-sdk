//
//  SocketDelegate.swift
//  SmartTracker
//
//  Created by Théo Damaville on 01/12/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

import Foundation
import UIKit

/**
 Possible message comming from the socketserver
 
 - Screenshot: A screenshot is requested (more below)
 */
enum SmartSocketEvent: String {
    /// Socket -> Device
    case Screenshot     = "ScreenshotRequest"
    /// Front -> Device
    case InterfaceAskedForLive  = "InterfaceAskedForLive"
    /// Front -> Device : live accepted
    case InterfaceAcceptedLive = "InterfaceAcceptedLive"
    /// Front -> Device : live refused
    case InterfaceRefusedLive = "InterfaceRefusedLive"
    /// Front -> Device
    case InterfaceAskedForScreenshot = "InterfaceAskedForScreenshot"
    /// Front -> Device : live stopped
    case InterfaceStoppedLive = "InterfaceStoppedLive"
    case InterfaceAbortedLiveRequest = "InterfaceAbortedLiveRequest"
}


class SocketDelegate: NSObject, SRWebSocketDelegate {
    let RECONNECT_INTERVAL:Double = 3.0
    var timer: NSTimer?
    let liveManager: LiveNetworkManager
    
    init(liveManager: LiveNetworkManager){
        self.liveManager = liveManager
    }
    
    /**
     Trigerred when we receive a message
     Based on the event name, we make a class that respond accordingly to the event
     
     - parameter webSocket: the ws
     - parameter message:   the message
     */
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        let jsonData = JSON.parse( (message as? String) ?? "{}")
        guard let event = jsonData["event"].string else {
            return
        }
        
        guard let data = jsonData["data"].dictionaryObject else {
            return
        }

        let socketEvent = SocketEventFactory.create(event, liveManager: self.liveManager, messageData: JSON(data))
        socketEvent.process()
    }
    
    /**
     Trigerred when the socket is open or reconnect
     
     - parameter webSocket: the ws
     */
    func webSocketDidOpen(webSocket: SRWebSocket!) {
        print("connected")
        timer?.invalidate()
    }
    
    func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        print("failed with message \(error)")
        autoReconnect()
    }
    
    /**
     Event triggered when the websocket is closed
     When try to autoreconnect every RECONNECT_INTERVAL
     
     - parameter webSocket: the current WS
     - parameter code:      the error code
     - parameter reason:    the reason msg
     - parameter wasClean:  ?
     */
    func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        print("closed with message \(reason) code \(code)")
        autoReconnect()
    }
    
    func webSocket(webSocket: SRWebSocket!, didReceivePong pongPayload: NSData!) {}
    
    func autoReconnect() {
        timer?.invalidate()
        timer = NSTimer(timeInterval: RECONNECT_INTERVAL, target: self, selector: #selector(SocketDelegate.reconnect(_:)), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
    }
    
    func reconnect(timer: NSTimer) {
        liveManager.sender?.open()
    }
}