// VoiceCodeXPCServiceProtocol.swift
import Foundation
import XcodeKit

@objc protocol VoiceCodeXPCServiceProtocol {
  func process(_ buffer: XCSourceTextBuffer, withReply: (XCSourceTextBuffer)->())
}
