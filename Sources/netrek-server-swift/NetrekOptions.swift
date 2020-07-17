//
//  NetrekOptions.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/15/20.
//

import Foundation
import ArgumentParser

struct NetrekOptions: ParsableCommand {
    @Option(help: "The fully qualified domainname of this netrek server for the metaserver to display")
    var domainName: String?
    
    @Option(help: "The directory to store netrek log files and user database.")
    var directory: String = "/tmp/netrek"
    
}
