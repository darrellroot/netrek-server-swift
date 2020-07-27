//
//  MetaserverUDP.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/14/20.
//

import Foundation
import NIO

class MetaserverUDP {
    //this class pushes data to the metaserver over udp:3521 periodically
    let metaserver = "metaserver1.netrek.org"
    let domainName: String
    let port = 3521
    let universe: Universe
    let remoteAddress: SocketAddress
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    //let bootstrap: DatagramBootstrap
    let channel: Channel?
    init?(universe: Universe) {
        guard let domainName = netrekOptions.domainName else {
            logger.error("\(#file) \(#function) Error: metaserver registration code activated without specifying domainName on CLI.  Try --help")
            return nil
        }
        self.domainName = domainName
        self.universe = universe
        guard let remoteAddress = try? SocketAddress.makeAddressResolvingHost(metaserver, port: port) else {
            logger.error("Failed to resolve host metaserver")
            return nil
        }
        self.remoteAddress = remoteAddress
        
        guard let channel = try? DatagramBootstrap(group: group)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .bind(host: "0.0.0.0", port: 0)
            .wait() else {
                logger.error("\(#file) \(#function) failed to initialize bootstrap")
                return nil
        }
        self.channel = channel
        
        
        /*guard let channel = try? bootstrap.bind(host: "", port: port).wait() else {
            logger.error("\(#file) \(#function) failed to initialize channel")
            return nil
        }
        self.channel = channel*/
        
    }
    
    func sendReport(ip: String, port: Int) {
        guard let remoteAddress = try? SocketAddress(ipAddress: ip, port: port) else {
            logger.error("\(#file) \(#function) Error: unable to resolve ip \(ip)")
            return
        }
        guard let channel = channel else {
            logger.error("\(#file) \(#function) Error: channel not initialized")
            return
        }
        let report = makeReport()
        let buffer = channel.allocator.buffer(string: report)
        let envelope = AddressedEnvelope<ByteBuffer>(remoteAddress: remoteAddress, data: buffer)
        _ = channel.writeAndFlush(envelope)
    }
    func makeReport() -> String {
        var returnValue = ""
        returnValue += "b\n"  // version
        returnValue += "\(domainName)\n" //netrek server DNS name
        switch netrekOptions.gameStyle {
        case .bronco:
            returnValue += "B\n"  // type
        case .empire:
            returnValue += "E\n"  // type
        }
        returnValue += "2592\n" // netrek server port
        returnValue += "0\n"
        let playerCount = self.universe.players.filter({$0.status != .free && $0.robot == nil}).count
        returnValue += "\(playerCount)\n"
        let freeCount = max(16 - playerCount,0)
        returnValue += "\(freeCount)\n"
        let tMode: String
        switch universe.gameState {
        case .intramural:
            tMode = "n"
        case .tmode:
            tMode = "y"
        }
        returnValue += "\(tMode)\n"
        returnValue += "n\n" //RSA
        if playerCount >= 16 {
            returnValue += "y\n" //gamefull
        } else {
            returnValue += "n\n" // gamefull
        }
        switch netrekOptions.gameStyle {
        case .bronco:
            returnValue += "Swift-IPv6-bronco\n" // comment
        case .empire:
            returnValue += "Swift-IPv6\n-empire" // comment
        }
        
        /* The detailed user list was not picked up by the metaserver successfully.  Rather than debug I chose not to share this information
         
        for player in universe.players.filter({$0.status != .free}) {
            returnValue += "\(player.slot.hex)\n"
            returnValue += "\(player.team.letter)\n"
            returnValue += "\(player.ship.rawValue)\n"
            if let user = player.user {
                returnValue += "\(user.rank.value)\n"
                returnValue += "\(user.name)\n"
                returnValue += "\(user.userinfo)\n"
            } else {
                returnValue += "0\n"
                returnValue += "unknownName\n"
                returnValue += "unknownInfo\n"
            }
            returnValue += "redacted\n" // user host
        }*/
        logger.debug("metaserver report \(returnValue)")
        return returnValue
    }
}

/*private final class MetaSender: ChannelOutboundHandler {
    public typealias OutboundIn = AddressedEnvelope<ByteBuffer>
    private var context: ChannelHandlerContext?
    
    public func channelActive(context: ChannelHandlerContext) {
        self.context = context
        logger.info("\(#file) \(#function)")
    }
    
    public func sendMessage(string: String, host: String, port: Int) {
        guard let context = self.context else {
            logger.error("\(#file) \(#function) Error: context nil")
            return
        }
        guard let remoteAddress = try? SocketAddress.makeAddressResolvingHost(host, port: port) else {
            logger.error("\(#file) \(#function) Error: unable to resolve host \(host)")
            return
        }
        let buffer = context.channel.allocator.buffer(string: string)
        let envelope = AddressedEnvelope<ByteBuffer>(remoteAddress: remoteAddress, data: buffer)
        _ = context.channel.writeAndFlush(envelope)

    }
}*/
