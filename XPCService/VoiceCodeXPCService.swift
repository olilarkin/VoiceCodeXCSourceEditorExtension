// VoiceCodeXPCService.swift
import Foundation
import Starscream

@objc class VoiceCodeXPCService: NSObject, VoiceCodeXPCServiceProtocol {
  
  func get_latest_command(withReply: (String) -> ()) {
    withReply("move-to-line-number")
  }
  
}
