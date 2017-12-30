/**
 * Copyright IBM Corporation 2016, 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

/// The type of a particular log message. Passed with the message to be logged to the
/// actual logger implementation. It is also used to enable filtering of the log based
/// on minimal type to log.
public enum LoggerMessageType: Int {
    /// Log message type for logging entering into a function
    case entry = 1
    /// Log message type for logging exiting from a function
    case exit = 2
    /// Log message type for logging a debugging message
    case debug = 3
    /// Log message type for logging messages in verbose mode
    case verbose = 4
    /// Log message type for logging an informational message
    case info = 5
    /// Log message type for logging a warning message
    case warning = 6
    /// Log message type for logging an error message
    case error = 7
    /// Do not log any messages at all
    case none = 8
    
    public static func all() -> [LoggerMessageType] {
        return [LoggerMessageType.entry, LoggerMessageType.exit, LoggerMessageType.debug, LoggerMessageType.verbose, LoggerMessageType.info, LoggerMessageType.warning, LoggerMessageType.error, LoggerMessageType.none]
    }
}

/// Implement the `CustomStringConvertible` protocol for the `LoggerMessageType` enum
extension LoggerMessageType: CustomStringConvertible {
    /// Convert a `LoggerMessageType` into a pritable format
    public var description: String {
        switch self {
        case .entry:
            return "ENTRY"
        case .exit:
            return "EXIT"
        case .debug:
            return "DEBUG"
        case .verbose:
            return "VERBOSE"
        case .info:
            return "INFO"
        case .warning:
            return "WARNING"
        case .error:
            return "ERROR"
        case .none:
            return "NONE"
        }
    }
}

/// A logger protocol implemented by Logger implementations. This API is used by Kitura
/// throughout its implementation when logging.
protocol Logger {
    
    /// Output a logged message.
    ///
    /// - Parameter type: The type of the message (`LoggerMessageType`) being logged.
    /// - Parameter msg: The message to be logged
    /// - Parameter functionName: The name of the function invoking the logger API.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API.
    /// - Parameter fileName: The file of the source code of the function invoking the
    ///                      logger API.
    func log(_ type: LoggerMessageType, msg: String,
             functionName: String, lineNum: Int, fileName: String)
    
    /// A function that will indicate if a message with a specified type (`LoggerMessageType`)
    /// will be output in the log (i.e. will not be filtered out).
    ///
    /// -Parameter type: The type of message that one wants to know if it will be output in the log.
    ///
    /// - Returns: A Bool indicating whether, if true, or not a message of the specified type
    ///           (`LoggerMessageType`) will be output.
    func isLogging(_ level: LoggerMessageType) -> Bool
    
}

/// A class of static members used by anyone who wants to log mesages.
internal class Log {
    
    /// An instance of the logger. It should usually be the one and only reference
    /// of the actual `Logger` protocol implementation in the system.
    internal static var logger: Logger?
    
    /// Log a log message for use when in verbose logging mode.
    ///
    /// - Parameter msg: The message to be logged
    /// - Parameter functionName: The name of the function invoking the logger API.
    ///                          Defaults to the actual name of the function invoking
    ///                          this function.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API. Defaults to the actual line of the actual
    ///                     function invoking this function.
    /// - Parameter fileName: The file of the source code of the function invoking the
    ///                      logger API. Defaults to the file of the actual function
    ///                      invoking this function.
    internal static func verbose(_ msg: @autoclosure () -> String, functionName: String = #function,
                               lineNum: Int = #line, fileName: String = #file ) {
        if let logger = logger, logger.isLogging(.verbose) {
            logger.log( .verbose, msg: msg(),
                        functionName: functionName, lineNum: lineNum, fileName: fileName)
        }
    }
    
    /// Log an informational message.
    ///
    /// - Parameter msg: The message to be logged
    /// - Parameter functionName: The name of the function invoking the logger API.
    ///                          Defaults to the actual name of the function invoking
    ///                          this function.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API. Defaults to the actual line of the actual
    ///                     function invoking this function.
    /// - Parameter fileName: The file of the source code of the function invoking the
    ///                      logger API. Defaults to the file of the actual function
    ///                      invoking this function.
    internal class func info(_ msg: @autoclosure () -> String, functionName: String = #function,
                           lineNum: Int = #line, fileName: String = #file) {
        if let logger = logger, logger.isLogging(.info) {
            logger.log( .info, msg: msg(),
                        functionName: functionName, lineNum: lineNum, fileName: fileName)
        }
    }
    
    /// Log a warning message.
    ///
    /// - Parameter msg: The message to be logged
    /// - Parameter functionName: The name of the function invoking the logger API.
    ///                          Defaults to the actual name of the function invoking
    ///                          this function.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API. Defaults to the actual line of the actual
    ///                     function invoking this function.
    /// - Parameter fileName: The file of the source code of the function invoking the
    ///                      logger API. Defaults to the file of the actual function
    ///                      invoking this function.
    internal class func warning(_ msg: @autoclosure () -> String, functionName: String = #function,
                              lineNum: Int = #line, fileName: String = #file) {
        if let logger = logger, logger.isLogging(.warning) {
            logger.log( .warning, msg: msg(),
                        functionName: functionName, lineNum: lineNum, fileName: fileName)
        }
    }
    
    /// Log an error message.
    ///
    /// - Parameter msg: The message to be logged
    /// - Parameter functionName: The name of the function invoking the logger API.
    ///                          Defaults to the actual name of the function invoking
    ///                          this function.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API. Defaults to the actual line of the actual
    ///                     function invoking this function.
    /// - Parameter fileName: The file of the source code of the function invoking the
    ///                      logger API. Defaults to the file of the actual function
    ///                      invoking this function.
    internal class func error(_ msg: @autoclosure () -> String, functionName: String = #function,
                            lineNum: Int = #line, fileName: String = #file) {
        if let logger = logger, logger.isLogging(.error) {
            logger.log( .error, msg: msg(),
                        functionName: functionName, lineNum: lineNum, fileName: fileName)
        }
    }
    
    /// Log a debuging message.
    ///
    /// - Parameter msg: The message to be logged
    /// - Parameter functionName: The name of the function invoking the logger API.
    ///                          Defaults to the actual name of the function invoking
    ///                          this function.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API. Defaults to the actual line of the actual
    ///                     function invoking this function.
    /// - Parameter fileName: The file of the source code of the function invoking the
    ///                      logger API. Defaults to the file of the actual function
    ///                      invoking this function.
    internal class func debug(_ msg: @autoclosure () -> String, functionName: String = #function,
                            lineNum: Int = #line, fileName: String = #file) {
        if let logger = logger, logger.isLogging(.debug) {
            logger.log( .debug, msg: msg(),
                        functionName: functionName, lineNum: lineNum, fileName: fileName)
        }
    }
    
    /// Log a message when entering a function.
    ///
    /// - Parameter msg: The message to be logged
    /// - Parameter functionName: The name of the function invoking the logger API.
    ///                          Defaults to the actual name of the function invoking
    ///                          this function.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API. Defaults to the actual line of the actual
    ///                     function invoking this function.
    /// - Parameter fileName: The file of the source code of the function invoking the
    ///                      logger API. Defaults to the file of the actual function
    ///                      invoking this function.
    internal class func entry(_ msg: @autoclosure () -> String, functionName: String = #function,
                            lineNum: Int = #line, fileName: String = #file) {
        if let logger = logger, logger.isLogging(.entry) {
            logger.log(.entry, msg: msg(),
                       functionName: functionName, lineNum: lineNum, fileName: fileName)
        }
    }
    
    /// Log a message when exiting a function.
    ///
    /// - Parameter msg: The message to be logged
    /// - Parameter functionName: The name of the function invoking the logger API.
    ///                          Defaults to the actual name of the function invoking
    ///                          this function.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API. Defaults to the actual line of the actual
    ///                     function invoking this function.
    /// - Parameter fileName: The file of the source code of the function invoking the
    ///                      logger API. Defaults to the file of the actual function
    ///                      invoking this function.
    internal class func exit(_ msg: @autoclosure () -> String, functionName: String = #function,
                           lineNum: Int = #line, fileName: String = #file) {
        if let logger = logger, logger.isLogging(.exit) {
            logger.log(.exit, msg: msg(),
                       functionName: functionName, lineNum: lineNum, fileName: fileName)
        }
    }
    
    /// A function that will indicate if a message with a specified type (`LoggerMessageType`)
    /// will be output in the log (i.e. will not be filtered out).
    ///
    /// - Parameter type: The type of message that one wants to know if it will be output in the log.
    ///
    /// - Returns: A Bool indicating whether, if true, or not a message of the specified type
    ///           (`LoggerMessageType`) will be output.
    internal class func isLogging(_ level: LoggerMessageType) -> Bool {
        guard let logger = logger else {
            return false
        }
        return logger.isLogging(level)
    }
}
