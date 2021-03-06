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
    
    let dateFormatter = DateFormatter()
    
    var metadata: Logger.Metadata = [:]
    
    var logLevel: Logger.Level
    
    var logFile: [Logger.Level: FileHandle] = [:]

    let fileManager = FileManager()
    public init(label: String) {
        if netrekOptions.debug {
            self.logLevel = .debug
        } else {
            self.logLevel = .info
        }
        //dateFormatter.dateStyle = .medium
        //dateFormatter.timeStyle = .medium
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        let directory = netrekOptions.directory
        if !fileManager.directoryExists(directory) {
            do {
                try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: false)
            } catch {
                fatalError("\(#file) \(#function) Unable to create directory \(directory) error \(error)")
            }
        }
        for logLevel in Logger.Level.allCases {
            let logFileName = "\(directory)/log.\(logLevel)"
            do {
                if fileManager.fileExists(atPath: logFileName) {
                    try fileManager.removeItem(atPath: "\(directory)/log.\(logLevel)")
                }
                guard fileManager.createFile(atPath: logFileName, contents: nil) else {
                    fatalError("\(#file) \(#function) Unable to create file \(logFileName)")
                }
                let thisLogFile = FileHandle(forWritingAtPath: logFileName)
                self.logFile[logLevel] = thisLogFile
            } catch {
                fatalError("\(#file) \(#function) Unable to delete file \(logFileName) error \(error)")
            }
        }
    }
    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata: Logger.Metadata?,
                    file: String, function: String, line: UInt) {
        let date = dateFormatter.string(from: Date())
        let longMessage = "\(date) \(file) \(function) \(line) \(level) \(message)\n"
        guard let data = longMessage.data(using: .utf8) else { return }
        guard let logFile = logFile[level] else { return }
        logFile.seekToEndOfFile()
        logFile.write(data)
        
        if level == .critical {
            print(longMessage)
        }

        //debugPrint("\(file) \(function) \(line) \(level) \(message)")
    }
    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set {
            self.metadata[metadataKey] = newValue
        }
    }
}
