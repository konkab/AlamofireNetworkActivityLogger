//
//  NetworkActivityLogger.swift
//  AlamofireNetworkActivityLogger
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Konstantin Kabanov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Alamofire
import Foundation

/// The level of logging detail.
public enum NetworkActivityLoggerLevel {
    /// Do not log requests or responses.
    case off

    /// Logs HTTP method, URL, header fields, & request body for requests, and status code, URL, header fields, response string, & elapsed time for responses.
    case debug

    /// Logs HTTP method & URL for requests, and status code, URL, & elapsed time for responses.
    case info

    /// Logs HTTP method & URL for requests, and status code, URL, & elapsed time for responses, but only for failed requests.
    case warn

    /// Equivalent to `.warn`
    case error

    /// Equivalent to `.off`
    case fatal
}

/// The output destination of logger.
public enum LoggerOutput {
    /// Logs to console output
    case console

    /// Logs to file output, logging all requests in one file
    case singleFile

    /// Logs to file output, logging to one file per request
    case multipleFiles

}

/// `NetworkActivityLogger` logs requests and responses made by Alamofire.SessionManager, with an adjustable level of detail.
public class NetworkActivityLogger {
    // MARK: - Properties

    /// The shared network activity logger for the system.
    public static let shared = NetworkActivityLogger()

    /// The level of logging detail. See NetworkActivityLoggerLevel enum for possible values. .info by default.
    public var level: NetworkActivityLoggerLevel = .info

    /// The output destination of logging. See NetworkActivityLoggerDestination enum for possible values. .console by default.
    public var destination: LoggerOutput = .console {
        didSet {
            switch destination {
                case .console:
                    logger = ConsoleOutput()
                case .singleFile:
                    logger = SingleFileOutput()
                    clearLoggingDirectory()
                case .multipleFiles:
                    logger = MultipleFilesOutput()
                    clearLoggingDirectory()
            }
        }
    }

    /// Omit requests which match the specified predicate, if provided.
    public var filterPredicate: NSPredicate?

    private let queue = DispatchQueue(label: "\(NetworkActivityLogger.self) Queue")

    private var logger: Output = ConsoleOutput()

    // MARK: - Internal - Initialization

    init() {}

    deinit {
        stopLogging()
    }

    // MARK: - Logging

    /// Start logging requests and responses.
    public func startLogging() {
        stopLogging()

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(
            self,
            selector: #selector(NetworkActivityLogger.requestDidStart(notification:)),
            name: Request.didResumeNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(NetworkActivityLogger.requestDidFinish(notification:)),
            name: Request.didFinishNotification,
            object: nil
        )
    }

    /// Stop logging requests and responses.
    public func stopLogging() {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Private - Notifications

    @objc private func requestDidStart(notification: Notification) {
        queue.async {
            guard let dataRequest = notification.request as? DataRequest,
                  let task = dataRequest.task,
                  let request = task.originalRequest,
                  let httpMethod = request.httpMethod,
                  let requestURL = request.url
            else {
                return
            }

            if let filterPredicate = self.filterPredicate, filterPredicate.evaluate(with: request) {
                return
            }

            var content = Content()
            guard let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) else { return }
            let identifier = (components.path + (components.query ?? "")).replacingOccurrences(of: "/", with: "|")
            content.identifier = identifier

            switch self.level {
                case .debug:
                    let cURL = dataRequest.cURLDescription()
                    content.data.append("\(httpMethod) '\(requestURL.absoluteString)':\n")
                    content.data.append("cURL:\n\(cURL)")

                case .info:
                    content.data.append("\(httpMethod) '\(requestURL.absoluteString)'\n")

                default:
                    break
            }

            try? self.logger.send(content: content)
        }
    }

    @objc private func requestDidFinish(notification: Notification) {
        queue.async {
            guard let dataRequest = notification.request as? DataRequest,
                  let task = dataRequest.task,
                  let metrics = dataRequest.metrics,
                  let request = task.originalRequest,
                  let httpMethod = request.httpMethod,
                  let requestURL = request.url
            else {
                return
            }

            if let filterPredicate = self.filterPredicate, filterPredicate.evaluate(with: request) {
                return
            }

            let elapsedTime = metrics.taskInterval.duration

            var content = Content()
            content.isReply = true
            guard let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) else { return }
            let identifier = (components.path + (components.query ?? "")).replacingOccurrences(of: "/", with: "|")
            content.identifier = identifier

            if let error = task.error {
                switch self.level {
                    case .debug, .info, .warn, .error:
                        content.isError = true
                        content.data.append("[Error] \(httpMethod) '\(requestURL.absoluteString)' [\(String(format: "%.04f", elapsedTime)) s]:\n")
                        content.data.append(error.localizedDescription + "\n")
                    default:
                        break
                }
            } else {
                guard let response = task.response as? HTTPURLResponse else {
                    return
                }

                switch self.level {
                    case .debug:
                        content.data.append("\(String(response.statusCode)) '\(requestURL.absoluteString)' [\(String(format: "%.04f", elapsedTime)) s]:\n\n")

                        self.appendHeaders(headers: response.allHeaderFields, content: &content)

                        guard let data = dataRequest.data else { break }

                        content.data.append("\nBody:\n")

                        do {
                            let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)

                            if let prettyString = String(data: prettyData, encoding: .utf8) {
                                content.data.append(prettyString + "\n")
                            }
                        } catch {
                            if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                                content.data.append((string as String) + "\n")
                            }
                        }
                    case .info:
                        content.data.append("\(String(response.statusCode)) '\(requestURL.absoluteString)' [\(String(format: "%.04f", elapsedTime)) s]\n")
                    default:
                        break
                }
            }
            try? self.logger.send(content: content)
        }

    }
}

private extension NetworkActivityLogger {
    func clearLoggingDirectory() {
        try? FileManager.default.removeItem(at: FileManager.default.outputURL)
        try? FileManager.default.createDirectory(at: FileManager.default.outputURL, withIntermediateDirectories: true)
        print("NetworkActivityLogger directory: " + FileManager.default.outputURL.absoluteString)
    }

    func appendHeaders(headers: [AnyHashable : Any], content: inout Content) {
        content.data.append("Headers: [\n")
        for (key, value) in headers {
            content.data.append("  \(key): \(value)\n")
        }
        content.data.append("]\n")
    }
}

struct Content {
    var identifier: String = ""
    var data: String = ""
    var isReply: Bool = false
    var isError: Bool = false
}

protocol Output {
    func send(content: Content) throws
}


class ConsoleOutput: Output {
    init() {}

    func send(content: Content) throws {
        logDivider()
        print(content.data)
        logDivider()
    }

    private func logDivider() {
        print("---------------------")
    }

}

class SingleFileOutput: Output {
    static var count: UInt = 0

    init() {}

    func send(content: Content) throws {
        SingleFileOutput.count += 1

        let url = FileManager.default.outputURL.appendingPathComponent("NetworkActivity.log")
        FileManager.default.createFileIfNeeded(at: url)
        do {
            let fileHandle = try FileHandle(forWritingTo: url)
            fileHandle.seekToEndOfFile()
            var output = FileHandlerOutputStream(fileHandle)
            let state = content.isReply ? (content.isError ? "🔴" : "🟢") : "⚪️"
            let count = String(format: "%03d", SingleFileOutput.count)
            print("------------------------------------ \(count) \(state) ------------------------------------\n", to: &output)
            print(content.data, to: &output)
        } catch {
            // Handle Error
        }
    }
}

class MultipleFilesOutput: Output {
    static var count: UInt = 0

    init() {}

    func send(content: Content) throws {
        MultipleFilesOutput.count += 1
        let state = content.isReply ? (content.isError ? "🔴" : "🟢") : "⚪️"
        let count = String(format: "%03d", MultipleFilesOutput.count)
        let url = FileManager.default.outputURL.appendingPathComponent("\(count) \(state) \(content.identifier).log")
        FileManager.default.createFileIfNeeded(at: url)
        do {
            let fileHandle = try FileHandle(forWritingTo: url)
            var output = FileHandlerOutputStream(fileHandle)
            print(content.data, to: &output)
        } catch {
            // Handle Error
        }
    }
}

extension FileManager {
    var outputURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Alamofire")
    }

    func createFileIfNeeded(at url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
    }
}

struct FileHandlerOutputStream: TextOutputStream {
    private let fileHandle: FileHandle
    let encoding: String.Encoding

    init(_ fileHandle: FileHandle, encoding: String.Encoding = .utf8) {
        self.fileHandle = fileHandle
        self.encoding = encoding
    }

    mutating func write(_ string: String) {
        if let data = string.data(using: encoding) {
            fileHandle.write(data)
        }
    }
}
