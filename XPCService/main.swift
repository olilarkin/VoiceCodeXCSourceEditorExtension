// main.swift
import Foundation

class ServiceDelegate : NSObject, NSXPCListenerDelegate {
  func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
    newConnection.exportedInterface = NSXPCInterface(with: VoiceCodeXPCServiceProtocol.self)
    let exportedObject = VoiceCodeXPCService()
    newConnection.exportedObject = exportedObject
    newConnection.resume()
    return true
  }
}

// Create the listener and resume it:
let delegate = ServiceDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate;
listener.resume()
