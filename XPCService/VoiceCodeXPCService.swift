// VoiceCodeXPCService.swift
import Foundation

@objc class VoiceCodeXPCService: NSObject, VoiceCodeXPCServiceProtocol {
  
  func get_latest_command(withReply: (String) -> ()) {
    withReply("move-to-line-number")
  }
  
}
