//
//  NetrekLogHandler.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/17/20.
//

import Foundation
import Logging

/* logger levels for netrek-server-swift
 trace   diagnostics within message decodes
 debug   every message received or sent
 info   normal game messages (planet cap, joins)
 notice TBD
 warning  TBD
 error   errors which impact one player
 critical   errors which can cause server to die
 */
struct NetrekLogHandler: LogHandler {
    public init(label: String) {
            
        }
    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata: Logger.Metadata?,
                    file: String, function: String, line: UInt) {
        debugPrint("\(file) \(function) \(line) \(level) \(message)")
    }
    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set {
            self.metadata[metadataKey] = newValue
        }
    }
    
    var metadata: Logger.Metadata = [:]
    
    var logLevel: Logger.Level = .debug
    
    
}
