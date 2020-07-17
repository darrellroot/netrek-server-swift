//
//  MetaserverChannelHandler.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/7/20.
//
/*  Close but does not work
     sending UDP metaserver packets is superior to listening
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
        let message = makeReport().data(using: .utf8)!
        let channel = context.channel
        logger.info("New metaserver connection from \(remoteAddress)")
        let buffer = context.channel.allocator.buffer(bytes: message)
        context.channel.writeAndFlush(buffer)
        context.close(promise: nil)
    }
    public func channelInactive(context: ChannelHandlerContext) {
        let channel = context.channel
        if let remoteAddress = context.remoteAddress {
            logger.info("metaserver connection from \(remoteAddress) complete")
        }
    }
    /*public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let id = ObjectIdentifier(context.channel)
        var read = self.unwrapInboundIn(data)
        logger.trace("\(#file) \(#function)")
    }*/
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("Error: ",error)
        if let remoteAddress = context.remoteAddress {
            logger.error("metaserver error from \(remoteAddress)")
        }
        context.close(promise: nil)
    }
    func makeReport() -> String {
        guard universe.players.filter({ $0.status != .free}).count > 0 else {
            let returnval = """

No one playing.
"""
            return returnval
        }
        let fakeUser = User(name: "unknown", password: "", userinfo: "unknown")
        let header = """
<>=======================================================================<>
  Pl: Rank       Name             Login      Host name                Type
<>=======================================================================<>\n
"""
        let spacer = """
<>=======================================================================<>\n
"""
        
        var returnValue: String = header
        for player in universe.players.filter( {$0.status != .free}) {
            let user = player.user ?? fakeUser
            let name = user.name.padding(toLength: 16, withPad: " ", startingAt: 0)
            let login = user.userinfo.padding(toLength: 10, withPad: " ", startingAt: 0)
            let ship = player.ship.description
            let hostname = "redacted".padding(toLength: 15, withPad: " ", startingAt: 0)
            let line = "  \(player.team.letter)\(player.slot.hex): Ensign     \(name) \(login) \(hostname)           \(ship)\n"
            returnValue += line
        }
        returnValue += spacer
        let fedCount = universe.players.filter({$0.team == .federation && $0.status != .free}).count
        let romCount = universe.players.filter({$0.team == .roman && $0.status != .free}).count
        let kazCount = universe.players.filter({$0.team == .kazari && $0.status != .free}).count
        let oriCount = universe.players.filter({$0.team == .orion && $0.status != .free}).count
        let fedString = String(format: "%2d",fedCount)
        let romString = String(format: "%2d",romCount)
        let kazString = String(format: "%2d",kazCount)
        let oriString = String(format: "%2d",oriCount)
        var countLine = "  Feds:\(fedString)   Roms:\(romString)   Kli:\(kazString)   Ori:\(oriString)\n"
        returnValue += countLine
        returnValue += "  No wait queue.\n"
        returnValue += spacer
        return returnValue
    }

}
 */
