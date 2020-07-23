//
//  main.swift
//  NetrekServer
//
//  Created by Darrell Root on 5/31/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import Foundation
import NIO
import Logging
import Lifecycle
import LifecycleNIOCompat
import Backtrace

print("Initializing server")

let netrekOptions = NetrekOptions.parseOrExit()

LoggingSystem.bootstrap(NetrekLogHandler.init)
let logger = Logger(label: "net.networkmom.netrek-server-swift")

let lifecycleConfiguration = ServiceLifecycle.Configuration(logger: logger)

let lifecycle = ServiceLifecycle(configuration: lifecycleConfiguration)

let universe = Universe()

Backtrace.install()

//first shutdown in file is last executed on macos
lifecycle.registerShutdown(label: "shutdownComplete",.sync(universe.shutdownComplete))

//second to last shutdown executed
lifecycle.registerShutdown(label: "shutdownWarning",.sync(universe.shutdownWarning))

//third to last shutdown executed
lifecycle.registerShutdown(label: "userDatabase", .sync(universe.userDatabase.save))

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


lifecycle.registerShutdown(label: "eventLoopGroup", .sync(group.syncShutdownGracefully))


lifecycle.start { error in
    // start completion handler.
    // if a startup error occurred you can capture it here
    if let error = error {
        logger.error("failed starting Netrek-server ☠️: \(error)")
    } else {
        logger.info("Netrek-server started successfully 🚀")
    }
}

let netrekChannel = try { () -> Channel in
    return try bootstrap.bind(host: "::", port: 2592).wait()
}()

guard let localAddress = netrekChannel.localAddress else {
    logger.critical("Address unable to bind")
    fatalError("Address unable to bind")
}
logger.info("Server started and listening on \(localAddress)")
print("Server started and listening on \(localAddress)")
//lifecycle.wait()

//timer is started in separate thread in universe.swift
print("Starting Run Loop")
RunLoop.current.run()

