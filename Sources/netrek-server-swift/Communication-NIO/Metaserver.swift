//
//  Metaserver.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/13/20.
//

import Foundation
import NIO

class Metaserver {
    
    var universe: Universe
    
    let group: MultiThreadedEventLoopGroup
    //let bootstrap: ServerBootstrap
    let channel: Channel
    init(universe: Universe) {
        self.universe = universe
        group = MultiThreadedEventLoopGroup(numberOfThreads: 2)
        
        let metaserverChannelHandler = MetaserverChannelHandler(universe: universe)
        let bootstrap = ServerBootstrap(group: group)
            .childChannelInitializer { channel in
                channel.pipeline.addHandler(metaserverChannelHandler)
                //channel.pipeline.addHandler(MetaHandler(universe: universe))
        }
        let channel = try! { () -> Channel in
            return try bootstrap.bind(host: "0.0.0.0", port: 2591).wait()
        }()
        self.channel = channel
        
        guard let localAddress = self.channel.localAddress else {
            fatalError("Address unable to bind")
        }

        print("Metaserver started and listening on \(localAddress)")

    }
}

/*private final class MetaHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    
    var universe: Universe
    init(universe: Universe) {
        self.universe = universe
    }
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        debugPrint("metaserver channel read")
        context.flush()
    }
    public func channelReadComplete(context: ChannelHandlerContext) {
        debugPrint("metaserver channelReadcomplete")
        context.flush()
    }
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        debugPrint("metaserver error caught")
        debugPrint("error: ",error)
        context.close(promise: nil)
    }
}*/
