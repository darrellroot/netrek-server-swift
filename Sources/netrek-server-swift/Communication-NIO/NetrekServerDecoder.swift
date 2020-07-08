//
//  NetrekServerDecoder.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/7/20.
//

import Foundation
import NIO

final class NetrekServerDecoder: ByteToMessageDecoder {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = ByteBuffer
    
    let msg_len = 80
    let name_len = 16
    let keymap_len = 96
    let reserved_size = 16
    let key_size = 32
    let playerMax = 100 // we ignore player updates for more than this
    
    
    func printData(_ data: [UInt8], success: Bool) {
        let printPacketDumps = true
        if printPacketDumps {
            var dumpString = "\(success) "
            for byte in data {
                let addString = String(format:"%x ",byte)
                dumpString += addString
            }
            debugPrint(dumpString)
        }
    }
    func printData(_ data: Data, success: Bool) {
        let printPacketDumps = true
        if printPacketDumps {
            var dumpString = "\(success) "
            for byte in data {
                let addString = String(format:"%x ",byte)
                dumpString += addString
            }
            debugPrint(dumpString)
        }
    }
    
    public func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        guard buffer.readableBytes > 0 else {
            return .needMoreData
        }
        guard let packetType = buffer.getBytes(at: 0, length: 1)?.first else {
            return .needMoreData
        }
        guard let packetLength = PACKET_SIZES[Int(packetType)], packetLength > 0 else {
            debugPrint("Warning: PacketAnalyzer.analyzeOnePacket received invalid packet type \(packetType)")
            throw NetrekError.invalidPacket
        }
        guard buffer.readableBytes >= packetLength else {
            return .needMoreData
        }
        guard let bytes = buffer.readBytes(length: packetLength) else {
            debugPrint("\(#file) \(#function) Unexpected inability to copy \(packetLength) data")
            throw NetrekError.invalidPacket
        }
        let data = Data(bytes)
        switch packetType {
        case 1: // CP_MESSAGE
            let group = Int(data[1])
            let indiv = Int(data[2])
            let pad1 = Int(data[3])
            let range = (4..<(4 + msg_len))
            let messageData = Data(data[4 ..< 4 + msg_len])
            var messageString = "message_decode_error"
            //            if let messageStringWithNulls = String(data: messageData, encoding: .utf8) {
            if let messageStringWithNulls = String(data: messageData, encoding: .ascii) {
                messageString = ""
                var done = false
                for char in messageStringWithNulls {
                    if !done && char != "\0" {
                        messageString.append(char)
                    } else {
                        done = true
                    }
                }
                
                //messageString = NetrekMath.sanitizeString(messageString)
                //appDelegate.messageViewController?.gotMessage(messageString)
                debugPrint(messageString)
                //printData(data, success: true)
            } else {
                debugPrint("PacketAnalyzer unable to decode message type 1")
                printData(data, success: false)
            }
            //messageString = NetrekMath.sanitizeString(messageString)
            guard let sender = universe.player(context: context) else {
                debugPrint("Unable to identify message sender for context \(context)")
                return .continue
            }
            
            
            debugPrint("Received CP_MESSAGE 1 to group \(group) indiv \(indiv) message \(messageString) from \(sender.slot)")
            //let spMessage = MakePacket.spMessage(message: messageString, from: UInt8(sender.slot))
            
            switch group {
            case 8: // MALL
                let prefix = "\(sender.team.letter)\(sender.slot)->ALL: "
                let spMessage = MakePacket.spMessage(message: prefix + messageString, from: UInt8(sender.slot))
                for player in universe.players.filter({ $0.status != .free}) {
                    if let context = player.context {
                        let buffer = context.channel.allocator.buffer(bytes: spMessage)
                        context.channel.writeAndFlush(buffer)
                    }
                    //player.connection?.send(data: spMessage)
                }
            case 4: // TEAM
                guard let destTeam = Team.allCases.filter({$0.rawValue == indiv}).first else {
                    debugPrint("\(#file) \(#function) unable to identify team \(indiv)")
                    return .continue
                }
                let prefix = "\(sender.team.letter)\(sender.slot)->\(destTeam.prefix): "
                let spMessage = MakePacket.spMessage(message: prefix + messageString, from: UInt8(sender.slot))
                
                for player in universe.players.filter({ $0.status != .free && $0.team.rawValue == indiv}) {
                    if let context = player.context {
                        let buffer = context.channel.allocator.buffer(bytes: spMessage)
                        context.channel.writeAndFlush(buffer)
                        //player.connection?.send(data: spMessage)
                    }
                }
            case 2: // INDIV
                
                guard let player = universe.players[safe: indiv], player.slot == indiv else {
                    debugPrint("\(#file) \(#function) unable to identify player \(indiv)")
                    return .continue
                }
                let prefix = "\(sender.team.letter)\(sender.slot)->\(player.team.letter)\(player.slot): "
                let spMessage = MakePacket.spMessage(message: prefix + messageString, from: UInt8(sender.slot))
                if let context = player.context {
                    let buffer = context.channel.allocator.buffer(bytes: spMessage)
                    context.channel.writeAndFlush(buffer)
                }
                //player.connection?.send(data: spMessage)
            default:
                debugPrint("\(#file) \(#function) Unexpected group \(group)")
        }//switch group inside case 1
        case 27: // CP_SOCKET 27
            let type = Int(data[1])
            let version = Int(data[2])
            let udpVersion = Int(data[3])
            let socket = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            debugPrint("Received CP_SOCKET 27 type \(type) version \(version) udpVersion \(udpVersion) socket \(socket)")
            universe.addPlayer(context: context)

        case 60: //CP_FEATURE
            let featureType = Int(data[1])
            let arg1 = Int(data[2])
            let arg2 = Int(data[3])
            let value = Int(data.subdata(in: 4..<8).to(type: UInt32.self).byteSwapped)
            let range = (8..<(8 + 80))
            let nameData = data.subdata(in: range)
            var nameString = "message_decode_error"
            if let nameStringWithNulls = String(data: nameData, encoding: .ascii) {
                nameString = ""
                var done = false
                for char in nameStringWithNulls {
                    if !done && char != "\0" {
                        nameString.append(char)
                    } else {
                        done = true
                    }
                }
                
                //debugPrint(nameString)
                //printData(data, success: true)
            } else {
                debugPrint("PacketAnalyzer unable to decode message type 60")
                printData(data, success: false)
            }
            //messageString = NetrekMath.sanitizeString(messageString)
            debugPrint("Received CP_FEATURE 60 type \(featureType) arg1 \(arg1) arg2 \(arg2) name \(nameString)")
            
            
            
        default:
            debugPrint("Default case: Received packet type \(packetType) length \(packetLength)\n")
            let _ = buffer.readBytes(length: packetLength)
            printData(data, success: true)
        }//switch packetType
        return .continue
        
    }//func decode
}//class netrekServerDecoder
