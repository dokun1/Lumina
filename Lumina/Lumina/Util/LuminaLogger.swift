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
    case trace = 1
    case debug = 2
    case info = 3
    case notice = 4
    case warning = 5
    case error = 6
    case critical = 7

    public var description: String {
        switch self {
        case .none: return "NONE"
        case .trace: return "TRACE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .notice: return "NOTICE"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .critical: return "CRITICAL"
        }
    }
}

internal class LuminaLogger {
    private static let logger = Logger(label: "com.okun.io.Lumina")
    internal static var level: LuminaLoggerLevel = .none

    static func trace(message: String, metadata: Logger.Metadata? = nil) {
        if level.rawValue >= 1 {
            logger.trace(Logger.Message(stringLiteral: message), metadata: metadata)
        }
    }

    static func debug(message: String, metadata: Logger.Metadata? = nil) {
        if level.rawValue >= 2 {
            logger.debug(Logger.Message(stringLiteral: message), metadata: metadata)
        }
    }

    static func info(message: String, metadata: Logger.Metadata? = nil) {
        if level.rawValue >= 3 {
            logger.info(Logger.Message(stringLiteral: message), metadata: metadata)
        }
    }

    static func notice(message: String, metadata: Logger.Metadata? = nil) {
        if level.rawValue >= 4 {
            logger.notice(Logger.Message(stringLiteral: message), metadata: metadata)
        }
    }

    static func warning(message: String, metadata: Logger.Metadata? = nil) {
        if level.rawValue >= 5 {
            logger.warning(Logger.Message(stringLiteral: message), metadata: metadata)
        }
    }

    static func error(message: String, metadata: Logger.Metadata? = nil) {
        if level.rawValue >= 6 {
            logger.error(Logger.Message(stringLiteral: message), metadata: metadata)
        }
    }

    static func critical(message: String, metadata: Logger.Metadata? = nil) {
        if level.rawValue >= 7 {
            logger.critical(Logger.Message(stringLiteral: message), metadata: metadata)
        }
    }
}
