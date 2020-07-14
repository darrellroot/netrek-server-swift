//
//  MetaserverChannelHandler.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/7/20.
//

import Foundation
import NIO

final class MetaserverChannelHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    let universe: Universe
    
    init(universe: Universe) {
        self.universe = universe
    }
    public func channelActive(context: ChannelHandlerContext) {
        let remoteAddress = context.remoteAddress!
        let channel = context.channel
        debugPrint("New metaserver connection from \(remoteAddress)")
        let message = "Hello world".data(using: .utf8)!
        let buffer = context.channel.allocator.buffer(bytes: message)
        context.channel.writeAndFlush(buffer)
    }
    public func channelInactive(context: ChannelHandlerContext) {
        let channel = context.channel
        if let remoteAddress = context.remoteAddress {
            debugPrint("metaserver connection from \(remoteAddress) complete")
        }
    }
    /*public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let id = ObjectIdentifier(context.channel)
        var read = self.unwrapInboundIn(data)
        debugPrint("\(#file) \(#function)")
    }*/
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        debugPrint("Error: ",error)
        if let remoteAddress = context.remoteAddress {
            debugPrint("metaserver error from \(remoteAddress)")
        }
        context.close(promise: nil)
    }
}
