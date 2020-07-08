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
    
    public func channelActive(context: ChannelHandlerContext) {
        let remoteAddress = context.remoteAddress!
        let channel = context.channel
        debugPrint("New channel from \(remoteAddress)")
    }
    public func channelInactive(context: ChannelHandlerContext) {
        let channel = context.channel
        let remoteAddress = context.remoteAddress!
        debugPrint("Channel from \(remoteAddress) inactive")
    }
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let id = ObjectIdentifier(context.channel)
        var read = self.unwrapInboundIn(data)
        debugPrint("\(#file) \(#function)")
    }
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        debugPrint("Error: ",error)
        context.close(promise: nil)
    }
}
