//
//  GenericLogger.swift
//  AlamofireNetworkActivityLogger
//
//  Created by Sohayb Hassoun on 4/14/17.
//  Copyright © 2017 RKT Studio. All rights reserved.
//

import Foundation

@objc public protocol GenericLogger {
    func log(_ value: Any) -> Void
    
    func logDebug(_ value: Any) -> Void
    
    func logInfo(_ value: Any) -> Void
    
    func logWarning(_ value: Any) -> Void
    
    func logError(_ value: Any) -> Void
    
    func logFatal(_ value: Any) -> Void
}
