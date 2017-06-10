// VoiceCodeXPCService.swift
import Foundation
import Starscream

@objc class VoiceCodeXPCService: NSObject, VoiceCodeXPCServiceProtocol, WebSocketDelegate  {

  var socket: WebSocket
  var messageReceived: String
  
  override init() {
    socket = WebSocket(url: URL(string: "ws://localhost:8081/")!)
    messageReceived = ""
    super.init()
    socket.delegate = self
    socket.connect()
  }
  
  func getLatestCommand(withReply: (String) -> ()) {

    while(!socket.isConnected) {
      // NSLog("connecting")
    }
    
    while(messageReceived == "") {
      // NSLog("waiting for message")
    }
    
    withReply(messageReceived)
    
    messageReceived = ""
  }
  
  func websocketDidConnect(socket: WebSocket) {
    NSLog("websocket is connected")
    //socket.write(string: "getCommand")
  }
  
  func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
    if let e = error {
      NSLog("websocket is disconnected: \(e.localizedDescription)")
    } else {
      NSLog("websocket disconnected")
    }
  }
  
  func websocketDidReceiveMessage(socket: WebSocket, text: String) {
    NSLog("Received text: \(text)")
    messageReceived = text
  }
  
  func websocketDidReceiveData(socket: WebSocket, data: Data) {
    NSLog("Received data: \(data.count)")
  }
}
