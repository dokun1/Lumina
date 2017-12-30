/**
 * Copyright IBM Corporation 2017
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

//import LoggerAPI
import Foundation

/// HeliumLogger, that prints to a TextOutputStream
internal class HeliumStreamLogger<OutputStream: TextOutputStream> : HeliumLogger {

    // stream to output the log to
    private var outputStream: OutputStream

    /// Create a `HeliumStreamLogger` instance and set it up as the logger used by the `LoggerAPI`
    /// protocol.
    /// - Parameter type: The most detailed message type (`LoggerMessageType`) to see in the
    ///                  output of the logger. Defaults to `verbose`.
    /// - Parameter outputStream: stream to output the log to
    internal static func use(_ type: LoggerMessageType = .verbose, outputStream: OutputStream) {
        Log.logger = HeliumStreamLogger(type, outputStream: outputStream)
    }

    /// Prevent accidentally invoking use() function of the superclass.
    /// Prints an error message, no logging is enabled.
    ///
    /// - Parameter type: The most detailed message type (`LoggerMessageType`) to see in the
    ///                  output of the logger.
    override internal class func use(_ type: LoggerMessageType = .verbose) {
        print("Unable to instiate HeliumStreamLogger. " +
              "Use HeliumStreamLogger.use(:LoggerMessageType:OutputStream) function.")
    }

    /// Create a `HeliumStreamLogger` instance
    ///
    /// - Parameter type: The most detailed message type (`LoggerMessageType`) to see in the
    ///                  output of the logger.
    internal init (_ type: LoggerMessageType = .verbose, outputStream: OutputStream) {
        self.outputStream = outputStream
        super.init(type)
    }

    override func doPrint(_ message: String) {
        print(message, to: &outputStream)
    }
}
