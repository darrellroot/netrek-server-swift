//
//  ServerConnection.swift
//  NetrekServer
//
//  Created by Darrell Root on 5/31/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
// 
// some code from https://rderik.com/blog/building-a-server-client-aplication-using-apple-s-network-framework/

/*
import Foundation
import Network

class ServerConnection {
    let MTU = 65536
    private static var nextId: Int = 0
    let connection: NWConnection
    //let id: Int
    let universe2: Universe
    let serverPacketAnalyzer: ServerPacketAnalyzer
    
    init(nwConnection: NWConnection, universe: Universe) {
        self.universe2 = universe
        self.serverPacketAnalyzer = ServerPacketAnalyzer(universe: universe)
        connection = nwConnection
        //self.id = ServerConnection.nextId
        ServerConnection.nextId += 1
        
        universe.addPlayer(connection: self)
        logger.info("Connected to \(connection.endpoint)")
    }
    var didStopCallback: ((Error?) -> Void)? = nil
    
    func start() {
        print("connection \(connection.endpoint) will start")
        connection.stateUpdateHandler = self.stateDidChange(to:)
        setupReceive()
        connection.start(queue: .main)
    }
    
    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .waiting(let error):
            connectionDidFail(error: error)
        case .ready:
            print("connection \(connection.endpoint) ready")
        case .failed(let error):
            connectionDidFail(error: error)
        default:
            break
        }
    }
    
    private func setupReceive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: MTU) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                logger.trace("received \(data.count) bytes of data from \(self.connection.endpoint)")
                self.serverPacketAnalyzer.analyze(incomingData: data, connection: self.connection)
                //let message = String(data: data, encoding: .utf8)
                //print("connection \(self.id) did receive, data: \(data as NSData) string: \(message ?? "-")")
                //self.send(data: data)
            }
            if isComplete {
                self.connectionDidEnd()
            } else if let error = error {
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive()
            }
        }
    }
    func send(data: Data) {
        self.connection.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
            //logger.trace("connection \(self.connection.endpoint) did send, data: \(data as NSData)")
        }))
    }
    
    func stop() {
        print("connection \(connection.endpoint) will stop")
    }
    
    private func connectionDidFail(error: Error) {
        print("connection \(connection.endpoint) did fail, error: \(error)")
        stop(error: error)
    }
    private func connectionDidEnd() {
        print("connection \(connection.endpoint) did end")
        stop(error: nil)
    }
    private func stop(error: Error?) {
        universe.connectionEnded(connection: self)
        connection.stateUpdateHandler = nil
        connection.cancel()
        if let didStopCallback = didStopCallback {
            self.didStopCallback = nil
            didStopCallback(error)
        }
    }
    
}
 */
