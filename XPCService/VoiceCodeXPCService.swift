// VoiceCodeXPCService.swift
import Foundation
import XcodeKit

@objc class VoiceCodeXPCService: NSObject, VoiceCodeXPCServiceProtocol {
  
  func process(_ buffer: XCSourceTextBuffer, withReply: (XCSourceTextBuffer) -> ()) {
    withReply(buffer)
  }
  
}
