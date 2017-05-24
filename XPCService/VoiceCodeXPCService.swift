// VoiceCodeXPCService.swift
import Foundation

@objc class VoiceCodeXPCService: NSObject, VoiceCodeXPCServiceProtocol {
  
  func uppercase(_ string: String, withReply: (String) -> ()) {
    withReply(string.uppercased())
  }
  
}
