//
//  LuminaLogger.swift
//  Lumina
//
//  Created by David Okun on 4/11/19.
//  Copyright © 2019 David Okun. All rights reserved.
//

import Foundation
import Logging

// TODO: Work out how to expose a Lumina-specific logger so apps don't have to import `Logging`, even though it's there.
public extension Logger.Level {
  var uppercasedStringRepresentation: String {
    self.rawValue.uppercased()
  }
}

public class LuminaLogger {
  private static let logger = Logger(label: "com.okun.io.Lumina")
  public static var level: Logger.Level = .critical
  
  static func trace(message: String, metadata: Logger.Metadata? = nil) {
    if level <= .trace {
      logger.trace("\(message)", metadata: metadata)
    }
  }
  
  static func debug(message: String, metadata: Logger.Metadata? = nil) {
    if level <= .debug {
      logger.debug("\(message)", metadata: metadata)
    }
  }
  
  static func info(message: String, metadata: Logger.Metadata? = nil) {
    if level <= .info {
      logger.info("\(message)", metadata: metadata)
    }
  }
  
  static func notice(message: String, metadata: Logger.Metadata? = nil) {
    if level <= .notice {
      logger.notice("\(message)", metadata: metadata)
    }
  }
  
  static func warning(message: String, metadata: Logger.Metadata? = nil) {
    if level <= .warning {
      logger.warning("\(message)", metadata: metadata)
    }
  }
  
  static func error(message: String, metadata: Logger.Metadata? = nil) {
    if level <= .error {
      logger.error("\(message)", metadata: metadata)
    }
  }
  
  static func critical(message: String, metadata: Logger.Metadata? = nil) {
    if level <= .critical {
      logger.critical("\(message)", metadata: metadata)
    }
  }
  
  static func wouldLog(level thisLoglevel: Logger.Level) -> Bool {
    return level <= thisLoglevel
  }
}
