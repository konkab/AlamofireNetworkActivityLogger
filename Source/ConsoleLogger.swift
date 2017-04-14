//
//  ConsoleLogger.swift
//  AlamofireNetworkActivityLogger
//
//  Created by Sohayb Hassoun on 4/14/17.
//  Copyright © 2017 RKT Studio. All rights reserved.
//

import Foundation

internal class ConsoleLogger: GenericLogger {
    func log(_ value: Any) -> Void {
        print(value)
    }
    
    func logDebug(_ value: Any) -> Void {
        print(value)
    }
    
    func logInfo(_ value: Any) -> Void {
        print(value)
    }
    
    func logWarning(_ value: Any) -> Void {
        print(value)
    }
    
    func logError(_ value: Any) -> Void {
        print(value)
    }
    
    func logFatal(_ value: Any) -> Void {
        print(value)
    }
}
