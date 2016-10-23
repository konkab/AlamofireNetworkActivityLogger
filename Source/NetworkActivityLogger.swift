//
//  NetworkActivityLogger.swift
//  AlamofireNetworkActivityLogger
//
//  Created by Konstantin Kabanov on 22/10/2016.
//  Copyright © 2016 RKT Studio. All rights reserved.
//

import Alamofire
import Foundation

public enum NetworkActivityLoggerLevel {
	case off
	case debug
	case info
	case warn
	case error
	case fatal
}

public class NetworkActivityLogger {
	// MARK: - Properties
	
	/// The shared network activity logger for the system.
	public static let shared = NetworkActivityLogger()
	
	/// The level of logging detail. See NetworkActivityLoggerLevel enum for possible values. .info by default.
	public var level: NetworkActivityLoggerLevel
	
	/// Omit requests which match the specified predicate, if provided.
	public var filterPredicate: NSPredicate?
	
	private var tasksStartDates: [URLSessionTask: Date]
	
	// MARK: - Internal - Initialization
	
	init() {
		level = .info
		tasksStartDates = [URLSessionTask: Date]()
	}
	
	deinit {
		stopLogging()
	}
	
	// MARK: - Logging
	
	public func startLogging() {
		stopLogging()
		
		let notificationCenter = NotificationCenter.default
		
		notificationCenter.addObserver(
			self,
			selector: #selector(NetworkActivityLogger.networkRequestDidStart(notification:)),
			name: Notification.Name.Task.DidResume,
			object: nil
		)
		
		notificationCenter.addObserver(
			self,
			selector: #selector(NetworkActivityLogger.networkRequestDidComplete(notification:)),
			name: Notification.Name.Task.DidComplete,
			object: nil
		)
	}
	
	public func stopLogging() {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Private - Notifications
	
	@objc private func networkRequestDidStart(notification: Notification) {
		guard let userInfo = notification.userInfo,
			let task = userInfo[Notification.Key.Task] as? URLSessionTask,
			let request = task.originalRequest,
			let httpMethod = request.httpMethod,
			let requestURL = request.url
			else {
				return
		}
		
		if let filterPredicate = filterPredicate, filterPredicate.evaluate(with: request) {
			return
		}
		
		tasksStartDates[task] = Date()
		
		switch level {
		case .debug:
			print("\(httpMethod) '\(requestURL.absoluteString)'")
			
			if let httpHeadersFields = request.allHTTPHeaderFields {
				for (key, value) in httpHeadersFields {
					print("\(key): \(value)")
				}
			}
			
			if let httpBody = request.httpBody, let httpBodyString = String(data: httpBody, encoding: .utf8) {
				print(httpBodyString)
			}
		case .info:
			print("\(httpMethod) '\(requestURL.absoluteString)'")
		default:
			break
		}
	}
	
	@objc private func networkRequestDidComplete(notification: Notification) {
		guard let userInfo = notification.userInfo,
			let task = userInfo[Notification.Key.Task] as? URLSessionTask,
			let request = task.originalRequest,
			let response = task.response as? HTTPURLResponse,
			let httpMethod = request.httpMethod,
			let responseURL = response.url
			else {
				return
		}
		
		if let filterPredicate = filterPredicate, filterPredicate.evaluate(with: request) {
			return
		}
		
		var elapsedTime: TimeInterval = 0.0
		
		if let startDate = tasksStartDates[task] {
			elapsedTime = Date().timeIntervalSince(startDate)
			tasksStartDates[task] = nil
		}
		
		if let error = task.error {
			switch level {
			case .debug,
			     .info,
			     .warn,
			     .error:
				print("[Error] \(httpMethod) '\(responseURL.absoluteString)' \(String(response.statusCode)) [\(String(format: "%.04f", elapsedTime)) s]: \(error)")
			default:
				break
			}
		} else {
			switch level {
			case .debug:
				print("\(String(response.statusCode)) '\(responseURL.absoluteString)' [\(String(format: "%.04f", elapsedTime)) s]")
				
				for (key, value) in response.allHeaderFields {
					print("\(key): \(value)")
				}
			case .info:
				print("\(String(response.statusCode)) '\(responseURL.absoluteString)' [\(String(format: "%.04f", elapsedTime)) s]")
			default:
				break
			}
		}
	}
}
