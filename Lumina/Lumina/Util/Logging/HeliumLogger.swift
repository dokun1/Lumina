/**
 * Copyright IBM Corporation 2015, 2017
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

import Foundation

/// The set of colors used when logging with colorized lines
internal enum TerminalColor: String {
    /// Log text in white.
    case white = "\u{001B}[0;37m" // white
    /// Log text in red, used for error messages.
    case red = "\u{001B}[0;31m" // red
    /// Log text in yellow, used for warning messages.
    case yellow = "\u{001B}[0;33m" // yellow
    /// Log text in the terminal's default foreground color.
    case foreground = "\u{001B}[0;39m" // default foreground color
    /// Log text in the terminal's default background color.
    case background = "\u{001B}[0;49m" // default background color
}

/// The set of substitution "variables" that can be used when formatting one's
/// logged messages.
internal enum HeliumLoggerFormatValues: String {
    /// The message being logged.
    case message = "(%msg)"
    /// The name of the function invoking the logger API.
    case function = "(%func)"
    /// The line in the source code of the function invoking the logger API.
    case line = "(%line)"
    /// The file of the source code of the function invoking the logger API.
    case file = "(%file)"
    /// The type of the logged message (i.e. error, warning, etc.).
    case logType = "(%type)"
    /// The time and date at which the message was logged.
    case date = "(%date)"

    static let All: [HeliumLoggerFormatValues] = [
        .message, .function, .line, .file, .logType, .date
    ]
}

/// A light weight implementation of the `LoggerAPI` protocol.
internal class HeliumLogger {

    /// Whether, if true, or not the logger output should be colorized.
    internal var colored: Bool = false

    /// If true, use the detailed format when a user logging format wasn't specified.
    internal var details: Bool = true

    /// If true, use the full file path, not just the filename.
    internal var fullFilePath: Bool = false

    /// If not nil, specifies the user specified logging format.
    /// For example: "[(%date)] [(%type)] [(%file):(%line) (%func)] (%msg)"
    internal var format: String? {
        didSet {
            if let format = self.format {
                customFormatter = HeliumLogger.parseFormat(format)
            } else {
                customFormatter = nil
            }
        }
    }

    /// If not nil, specifies the format used when adding the date and the time to the
    /// logged messages
    internal var dateFormat: String? {
        didSet {
            dateFormatter = HeliumLogger.getDateFormatter(format: dateFormat, timeZone: timeZone)
        }
    }

    /// If not nil, specifies the timezone used in the date time format
    internal var timeZone: TimeZone? {
        didSet {
            dateFormatter = HeliumLogger.getDateFormatter(format: dateFormat, timeZone: timeZone)
        }
    }

    /// default date format - ISO 8601
    internal static let defaultDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

    fileprivate var dateFormatter: DateFormatter = HeliumLogger.getDateFormatter()

    static func getDateFormatter(format: String? = nil, timeZone: TimeZone? = nil) -> DateFormatter {
        let formatter = DateFormatter()

        if let dateFormat = format {
            formatter.dateFormat = dateFormat
        } else {
            formatter.dateFormat = defaultDateFormat
        }

        if let timeZone = timeZone {
            formatter.timeZone = timeZone
        }

        return formatter
    }

    #if os(Linux) && !swift(>=3.1)
    typealias NSRegularExpression = RegularExpression
    #endif

    private static var tokenRegex: NSRegularExpression? = {
        do {
            return try NSRegularExpression(pattern: "\\(%\\w+\\)", options: [])
        } catch {
            print("Error creating HeliumLogger tokenRegex: \(error)")
            return nil
        }
    }()

    fileprivate var customFormatter: [LogSegment]?

    enum LogSegment: Equatable {
        case token(HeliumLoggerFormatValues)
        case literal(String)

        static func == (lhs: LogSegment, rhs: LogSegment) -> Bool {
            switch (lhs, rhs) {
            case (.token(let lhsToken), .token(let rhsToken)) where lhsToken == rhsToken:
                return true
            case (.literal(let lhsLiteral), .literal(let rhsLiteral)) where lhsLiteral == rhsLiteral:
                return true
            default:
                return false
            }
        }
    }

    static func parseFormat(_ format: String) -> [LogSegment] {
        var logSegments = [LogSegment]()

        let nsFormat = NSString(string: format)
        let matches = tokenRegex!.matches(in: format, options: [], range: NSMakeRange(0, nsFormat.length))

        guard !matches.isEmpty else {
            // entire format is a literal, probably a typo in the format
            logSegments.append(LogSegment.literal(format))
            return logSegments
        }

        var loc = 0
        for (index, match) in matches.enumerated() {
            // possible literal segment before token match
            if loc < match.range.location {
                let segment = nsFormat.substring(with: NSMakeRange(loc, match.range.location - loc))
                if !segment.isEmpty {
                    logSegments.append(LogSegment.literal(segment))
                }
            }

            // token regex match, may not be a valid formatValue
            let segment = nsFormat.substring(with: match.range)
            loc = match.range.location + match.range.length
            if let formatValue = HeliumLoggerFormatValues(rawValue: segment) {
                logSegments.append(LogSegment.token(formatValue))
            } else {
                logSegments.append(LogSegment.literal(segment))
            }

            // possible literal segment after LAST token match
            let nextIndex = index + 1
            if nextIndex >= matches.count {
                let segment = nsFormat.substring(from: loc)
                if !segment.isEmpty {
                    logSegments.append(LogSegment.literal(segment))
                }
            }
        }

        return logSegments
    }

    /// Create a `HeliumLogger` instance and set it up as the logger used by the `LoggerAPI`
    /// protocol.
    /// - Parameter type: The most detailed message type (`LoggerMessageType`) to see in the
    ///                  output of the logger. Defaults to `verbose`.
    internal class func use(_ type: LoggerMessageType = .verbose) {
        Log.logger = HeliumLogger(type)
        setbuf(stdout, nil)
    }

    fileprivate let type: LoggerMessageType

    /// Create a `HeliumLogger` instance
    ///
    /// - Parameter type: The most detailed message type (`LoggerMessageType`) to see in the
    ///                  output of the logger.
    internal init (_ type: LoggerMessageType = .verbose) {
        self.type = type
    }

    internal func disable() {

    }

    func doPrint(_ message: String) {
        print(message)
    }
}

/// Implement the `LoggerAPI` protocol in the `HeliumLogger` class.
extension HeliumLogger : Logger {

    /// Output a logged message.
    ///
    /// - Parameter type: The type of the message (`LoggerMessageType`) being logged.
    /// - Parameter msg: The mesage to be logged
    /// - Parameter functionName: The name of the function invoking the logger API.
    /// - Parameter lineNum: The line in the source code of the function invoking the
    ///                     logger API.
    /// - Parameter fileName: The file of the source code of the function invoking the
    ///                      logger API.
    internal func log(_ type: LoggerMessageType, msg: String, functionName: String, lineNum: Int, fileName: String) {
        guard isLogging(type) else {
            return
        }

        let message = formatEntry(type: type, msg: msg, functionName: functionName, lineNum: lineNum, fileName: fileName)
        doPrint(message)
    }
    
    func formatEntry(type: LoggerMessageType, msg: String,
                     functionName: String, lineNum: Int, fileName: String) -> String {

        let message: String
        if let formatter = customFormatter {
            var line = ""
            for logSegment in formatter {
                let value: String

                switch logSegment {
                case .literal(let literal):
                    value = literal
                case .token(let token):
                    switch token {
                    case .date:
                        value = formatDate()
                    case .logType:
                        value = type.description
                    case .file:
                        value = getFile(fileName)
                    case .line:
                        value = "\(lineNum)"
                    case .function:
                        value = functionName
                    case .message:
                        value = msg
                    }
                }

                line.append(value)
            }
            message = line
        } else if details {
            message = "[\(formatDate())] [\(type)] [\(getFile(fileName)):\(lineNum) \(functionName)] \(msg)"
        } else {
            message = "[\(formatDate())] [\(type)] \(msg)"
        }

        guard colored else {
            return message
        }

        let color : TerminalColor
        switch type {
        case .warning:
            color = .yellow
        case .error:
            color = .red
        default:
            color = .foreground
        }

        return color.rawValue + message + TerminalColor.foreground.rawValue
    }

    func formatDate(_ date: Date = Date()) -> String {
        return dateFormatter.string(from: date)
    }

    func getFile(_ path: String) -> String {
        if self.fullFilePath {
            return path
        }
        guard let range = path.range(of: "/", options: .backwards) else {
            return path
        }

        #if swift(>=3.2)
            return String(path[range.upperBound...])
        #else
            return path.substring(from: range.upperBound)
        #endif
    }

    /// A function that will indicate if a message with a specified type (`LoggerMessageType`)
    /// will be outputed in the log (i.e. will not be filtered out).
    ///
    /// -Parameter type: The type of message that one wants to know if it will be output in the log.
    ///
    /// - Returns: A Bool indicating whether, if true, or not a message of the specified type
    ///           (`LoggerMessageType`) would be output.
    internal func isLogging(_ type: LoggerMessageType) -> Bool {
        return type.rawValue >= self.type.rawValue
    }
}
