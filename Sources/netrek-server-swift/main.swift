//
//  main.swift
//  NetrekServer
//
//  Created by Darrell Root on 5/31/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import Foundation

print("Initializing server")

let universe = Universe()
let server = Server(port: 2592, universe: universe)
try! server.start()

RunLoop.current.run()
