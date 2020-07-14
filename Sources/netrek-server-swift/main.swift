//
//  main.swift
//  NetrekServer
//
//  Created by Darrell Root on 5/31/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import Foundation
import NIO

print("Initializing server")

let universe = Universe()
//let server = Server(port: 2592, universe: universe)
//try! server.start()

let netrekChannelHandler = NetrekChannelHandler(universe: universe)
let group = MultiThreadedEventLoopGroup(numberOfThreads: 2)
let bootstrap = ServerBootstrap(group: group)
    .serverChannelOption(ChannelOptions.backlog, value: 32)
    .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr),value: 1)
    .childChannelInitializer { channel in
        channel.pipeline.addHandler(netrekChannelHandler).flatMap { v in
        channel.pipeline.addHandler(ByteToMessageHandler(NetrekServerDecoder()))
        }
}
    .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
    .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
defer {
    try! group.syncShutdownGracefully()
}

let channel = try { () -> Channel in
    return try bootstrap.bind(host: "::", port: 2592).wait()
}()

guard let localAddress = channel.localAddress else {
    fatalError("Address unable to bind")
}

print("Server started and listening on \(localAddress)")

let metaserver = Metaserver(universe: universe)
/*let nioQueue = DispatchQueue(label: "swift-nio")

nioQueue.async {
    // This will never unblock as we don't close the ServerChannel.
    //debugPrint("hi")
    try! channel.closeFuture.wait()
}*/
RunLoop.current.run()
