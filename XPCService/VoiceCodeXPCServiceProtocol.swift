// VoiceCodeXPCServiceProtocol.swift
import Foundation

@objc protocol VoiceCodeXPCServiceProtocol {
  func get_latest_command(withReply: (String)->())
}
