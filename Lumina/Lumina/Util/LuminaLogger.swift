//
//  LuminaLogger.swift
//  Lumina
//
//  Created by David Okun on 4/11/19.
//  Copyright © 2019 David Okun. All rights reserved.
//

import Foundation

public extension Logger.Level {
    var uppercasedStringRepresentation: String {
        switch self {
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
    internal static var level: Logger.Level = .critical

    static func trace(message: String, metadata: Logger.Metadata? = nil) {
        if level >= .trace {
            logger.trace("\(message)", metadata: metadata)
        }
    }

    static func debug(message: String, metadata: Logger.Metadata? = nil) {
        if level >= .debug {
            logger.debug("\(message)", metadata: metadata)
        }
    }

    static func info(message: String, metadata: Logger.Metadata? = nil) {
        if level >= .info {
            logger.info("\(message)", metadata: metadata)
        }
    }

    static func notice(message: String, metadata: Logger.Metadata? = nil) {
        if level >= .notice {
            logger.notice("\(message)", metadata: metadata)
        }
    }

    static func warning(message: String, metadata: Logger.Metadata? = nil) {
        if level >= .warning {
            logger.warning("\(message)", metadata: metadata)
        }
    }

    static func error(message: String, metadata: Logger.Metadata? = nil) {
        if level >= .error {
            logger.error("\(message)", metadata: metadata)
        }
    }

    static func critical(message: String, metadata: Logger.Metadata? = nil) {
        if level >= .critical {
            logger.critical("\(message)", metadata: metadata)
        }
    }
}
