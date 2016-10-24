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
    case Off
    
    /// Logs HTTP method, URL, header fields, & request body for requests, and status code, URL, header fields, response string, & elapsed time for responses.
    case Debug
    
    /// Logs HTTP method & URL for requests, and status code, URL, & elapsed time for responses.
    case Info
    
    /// Logs HTTP method & URL for requests, and status code, URL, & elapsed time for responses, but only for failed requests.
    case Warn
    
    /// Equivalent to `.warn`
    case Error
    
    /// Equivalent to `.off`
    case Fatal
}

/// `NetworkActivityLogger` logs requests and responses made by Alamofire.SessionManager, with an adjustable level of detail.
public class NetworkActivityLogger {
    // MARK: - Properties
    
    /// The shared network activity logger for the system.
    public static let sharedLogger = NetworkActivityLogger()
    
    /// The level of logging detail. See NetworkActivityLoggerLevel enum for possible values. .info by default.
    public var level: NetworkActivityLoggerLevel
    
    /// Omit requests which match the specified predicate, if provided.
    public var filterPredicate: NSPredicate?
    
    private var startDates: [NSURLSessionTask: NSDate]
    
    // MARK: - Internal - Initialization
    
    init() {
        level = .Info
        startDates = [NSURLSessionTask: NSDate]()
    }
    
    deinit {
        stopLogging()
    }
    
    // MARK: - Logging
    
    /// Start logging requests and responses.
    public func startLogging() {
        stopLogging()
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        notificationCenter.addObserver(
            self,
            selector: #selector(NetworkActivityLogger.networkRequestDidStart(_:)),
            name: Notifications.Task.DidResume,
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(NetworkActivityLogger.networkRequestDidComplete(_:)),
            name: Notifications.Task.DidComplete,
            object: nil
        )
    }
    
    /// Stop logging requests and responses.
    public func stopLogging() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Private - Notifications
    
    @objc private func networkRequestDidStart(notification: NSNotification) {
        guard let task = notification.object as? NSURLSessionTask,
            let request = task.originalRequest,
            let httpMethod = request.HTTPMethod,
            let requestURL = request.URL
            else {
                return
        }
        
        if let filterPredicate = filterPredicate where filterPredicate.evaluateWithObject(request) {
            return
        }
        
        startDates[task] = NSDate()
        
        switch level {
        case .Debug:
            print("\(httpMethod) '\(requestURL.absoluteString)':")
            
            if let httpHeadersFields = request.allHTTPHeaderFields {
                for (key, value) in httpHeadersFields {
                    print("\(key): \(value)")
                }
            }
            
            if let httpBody = request.HTTPBody, let httpBodyString = String(data: httpBody, encoding: NSUTF8StringEncoding) {
                print(httpBodyString)
            }
        case .Info:
            print("\(httpMethod) '\(requestURL.absoluteString)'")
        default:
            break
        }
    }
    
    @objc private func networkRequestDidComplete(notification: NSNotification) {
        guard let task = notification.object as? NSURLSessionTask,
            let request = task.originalRequest,
            let httpMethod = request.HTTPMethod,
            let requestURL = request.URL
            else {
                return
        }
        
        if let filterPredicate = filterPredicate where filterPredicate.evaluateWithObject(request) {
            return
        }
        
        var elapsedTime: NSTimeInterval = 0.0
        
        if let startDate = startDates[task] {
            elapsedTime = NSDate().timeIntervalSinceDate(startDate)
            startDates[task] = nil
        }
        
        if let error = task.error {
            switch level {
            case .Debug,
                 .Info,
                 .Warn,
                 .Error:
                print("[Error] \(httpMethod) '\(requestURL.absoluteString)' [\(String(format: "%.04f", elapsedTime)) s]:")
                print(error)
            default:
                break
            }
        } else {
            guard let response = task.response as? NSHTTPURLResponse else {
                return
            }
            
            switch level {
            case .Debug:
                print("\(String(response.statusCode)) '\(requestURL.absoluteString)' [\(String(format: "%.04f", elapsedTime)) s]:")
                
                for (key, value) in response.allHeaderFields {
                    print("\(key): \(value)")
                }
            case .Info:
                print("\(String(response.statusCode)) '\(requestURL.absoluteString)' [\(String(format: "%.04f", elapsedTime)) s]")
            default:
                break
            }
        }
    }
}
