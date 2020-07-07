//
//  Server.swift
//  NetrekServer
//
//  Created by Darrell Root on 5/31/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//
// some code from https://rderik.com/blog/building-a-server-client-aplication-using-apple-s-network-framework/

import Foundation
import Network

class Server {
    let port: NWEndpoint.Port
    let listener: NWListener
    let universe: Universe
    
    //private var connectionsById: [Int: ServerConnection] = [:]
    
    init(port: UInt16, universe: Universe) {
        self.port = NWEndpoint.Port(rawValue: port)!
        self.universe = universe
        listener = try! NWListener(using: .tcp, on: self.port)
    }
    
    func start() throws {
        debugPrint("Server starting...")
        listener.stateUpdateHandler = self.stateDidChange(to:)
        listener.newConnectionHandler = self.didAccept(nwConnection:)
        listener.start(queue: .main)
    }
    
    func stateDidChange(to newState: NWListener.State) {
        switch newState {
        case .ready:
            print("Server ready.")
        case .failed(let error):
            print("Server failure error: \(error.localizedDescription)")
            exit(EXIT_FAILURE)
        default:
            break
        }
    }
    
    private func didAccept(nwConnection: NWConnection) {
        let connection = ServerConnection(nwConnection: nwConnection, universe: universe)
        //self.universe.connectionsById[connection.id] = connection
        connection.start()
        //connection.send(data: "Welcome you are connection: \(connection.id)".data(using: .utf8)!)
        print("server did open connection \(connection.connection.endpoint)")
    }
    /*private func connectionDidStop(_ connection: ServerConnection) {
        self.universe.connectionsById.removeValue(forKey: connection.id)
        print("server did close connection \(connection.id)")
    }*/
    private func stop() {
        self.listener.stateUpdateHandler = nil
        self.listener.newConnectionHandler = nil
        self.listener.cancel()
        for player in self.universe.players {
            player.connection?.didStopCallback = nil
            player.connection?.stop()
            player.connection = nil
        }
        //self.universe.connectionsById.removeAll()
 
    }
}
