//
//  NetrekOptions.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/15/20.
//

import Foundation
import ArgumentParser

enum GameStyle: String, EnumerableFlag {
    case bronco
    case empire
}
struct NetrekOptions: ParsableCommand {
    @Option(help: "The fully qualified domainname of this netrek server for the metaserver to display")
    var domainName: String?
    
    @Option(help: "The directory to store netrek log files and user database.")
    var directory: String = "/tmp/netrek"
    
    @Flag(help: "Enables debug logging. Warning: fills up filesystems in a few hours.")
    var debug = false
    
    @Flag(help: "Specifies the Netrek Game Style.")
    var gameStyle = .empire
}
