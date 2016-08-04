//
//  SocketSender.swift
//  SmartTracker
//
//  Created by Théo Damaville on 01/12/2015.
//  Copyright © 2015 AT Internet. All rights reserved.
//

/*

The socket sender act as a singleton that has a buffer of event
it buffers the event until it's paired when paired, it send all the messages
act as the Model considering MVC : M:SocketSender V:SmartToolBar C:SmartTracker
 
*/

import Foundation

public class SocketSender {
    
    var socket: SRWebSocket?
    var timer: NSTimer?
    let RECONNECT_INTERVAL: Double = 2.0
    var screenBuffer: String?
    var socketHandler: SocketDelegate
    let URL: String
    let liveManager: LiveNetworkManager
    
    var queue:Array<String> = []
    init(liveManager: LiveNetworkManager, token: String) {
        self.URL = "ws://172.20.23.137:5000/"+token
        //self.URL = "ws://tagsmartsdk.eu-west-1.elasticbeanstalk.com:5000/"+token
        self.liveManager = liveManager
        self.socketHandler = SocketDelegate(liveManager: liveManager)
    }
    
    /**
     open the socket
     */
    func open() {
        if isConnected() || ATInternet.sharedInstance.defaultTracker.enableLiveTagging == false || socket?.readyState == SRReadyState.CONNECTING {
            return
        }
        print(URL)
        let url = NSURL(string: URL)
        socket = SRWebSocket(URL:url)
        socket?.delegate = socketHandler
        socket?.open()
    }
    
    /**
     Close socket
     */
    func close() {
        if isConnected() {
            socket?.close()
        }
    }
    
    /**
     check if the socket is connected
     
     - returns: the state of the connexion
     */
    private func isConnected() -> Bool {
        return (socket != nil) && (socket?.readyState == SRReadyState.OPEN)
    }
    
    /**
     send all events in the buffer list
     */
    func sendAll() {
        assert(isConnected())
        assert(self.liveManager.networkStatus == .Connected)
        if queue.count == 0 {
            socket?.send(screenBuffer)
        }
        while queue.count > 0 {
            self.sendFirst()
        }
    }
    
    /**
     send a JSON message to the server
     
     - parameter json: the message as a String (JSON formatted)
     */
    func sendMessage(json: String) {
        let obj = json.toJSONObject() as! NSDictionary
        let eventName = obj.objectForKey("event") as! String
        print(eventName)
        if self.liveManager.networkStatus != .Connected {
            if eventName == "app" {
                self.queue.append(json)
            }
            else if eventName == "viewDidAppear" {
                if self.queue.count > 1 {
                    self.queue.popLast()
                }
                self.queue.append(json)
                screenBuffer = json
            }
        } else {
            if eventName == "viewDidAppear" {
                screenBuffer = json
            }
            self.queue.append(json)
            self.sendAll()
        }
    }
    
    /**
     Send a message even if not paired
     
     - parameter json: the message
     */
    func sendMessageForce(json: String) {
        if isConnected() {
            socket?.send(json)
        }
    }
    
    func startAskingForLive() {
        timer?.invalidate()
        timer = NSTimer(timeInterval: RECONNECT_INTERVAL, target: self, selector: #selector(SocketSender.sendAskingForLive), userInfo: nil, repeats: true)
        timer?.fire()
        NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
    }
    
    @objc func sendAskingForLive() {
        sendMessageForce(DeviceAskingForLive().description)
    }
    
    func stopAskingForLive() {
        timer?.invalidate()
    }
    
    /**
     Send the first message (act as a FIFO)
     */
    private func sendFirst() {
        let msg = queue.first
        socket?.send(msg)
        self.queue.removeAtIndex(0)
    }
}