//
//  LuminaLogger.swift
//  Lumina
//
//  Created by David Okun on 4/11/19.
//  Copyright © 2019 David Okun. All rights reserved.
//

import Foundation

public enum LuminaLoggerLevel: Int, CaseIterable {
    case none = 0
    case info = 1
    case notice = 2
    case warning = 3
    case critical = 4
    case error = 5
    case debug = 6
    case trace = 7

    public var description: String {
        switch self {
        case .none: return "NONE"
        case .info: return "INFO"
        case .notice: return "NOTICE"
        case .warning: return "WARNING"
        case .critical: return "CRITICAL"
        case .error: return "ERROR"
        case .debug: return "DEBUG"
        case .trace: return "TRACE"
        }
    }
}

internal class LuminaLogger {
    private static let logger = Logger(label: "com.okun.io.Lumina")
    internal static var level: LuminaLoggerLevel = .none

    static func trace(message: String, metadata: Logger.Metadata? = nil) {
        if level.rawValue >= 7 {
            logger.trace(Logger.Message(stringLiteral: message), metadata: metadata)
        }
    }

    static func debug(message: String, metadata: Logger.Metadata? = nil) {
        if level.rawValue >= 6 {
            logger.debug(Logger.Message(stringLiteral: message), metadata: metadata)
        }
    }

    static func info(message: String, metadata: Logger.Metadata? = nil) {
        if level.rawValue >= 1 {
            logger.info(Logger.Message(stringLiteral: message), metadata: metadata)
        }
    }

    static func notice(message: String, metadata: Logger.Metadata? = nil) {
        if level.rawValue >= 2 {
            logger.notice(Logger.Message(stringLiteral: message), metadata: metadata)
        }
    }

    static func warning(message: String, metadata: Logger.Metadata? = nil) {
        if level.rawValue >= 3 {
            logger.warning(Logger.Message(stringLiteral: message), metadata: metadata)
        }
    }

    static func critical(message: String, metadata: Logger.Metadata? = nil) {
        if level.rawValue >= 4 {
            logger.critical(Logger.Message(stringLiteral: message), metadata: metadata)
        }
    }

    static func error(message: String, metadata: Logger.Metadata? = nil) {
        if level.rawValue >= 5 {
            logger.error(Logger.Message(stringLiteral: message), metadata: metadata)
        }
    }
}
