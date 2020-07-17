//
//  NetrekChannelHandler.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/7/20.
//

import Foundation
import NIO

final class NetrekChannelHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    let universe: Universe
    
    init(universe: Universe) {
        self.universe = universe
    }
    public func channelActive(context: ChannelHandlerContext) {
        let remoteAddress = context.remoteAddress!
        let channel = context.channel
        logger.info("New channel from \(remoteAddress)")
    }
    public func channelInactive(context: ChannelHandlerContext) {
        let channel = context.channel
        if let remoteAddress = context.remoteAddress, let player = universe.player(remoteAddress: remoteAddress) {
            player.disconnected()
        }
    }
    /*public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let id = ObjectIdentifier(context.channel)
        var read = self.unwrapInboundIn(data)
        logger.trace("\(#file) \(#function)")
    }*/
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("Error: \(error)")
        if let remoteAddress = context.remoteAddress, let player = universe.player(remoteAddress: remoteAddress) {
            player.disconnected()
        } else {
            logger.error("Unable to disconnect player for context \(context)")
        }

        context.close(promise: nil)
    }
}
