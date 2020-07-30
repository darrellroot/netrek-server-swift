//
//  NetrekServerDecoder.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/7/20.
//

import Foundation
import NIO
import Logging

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
            logger.trace("\(dumpString)")
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
            logger.trace("\(dumpString)")
        }
    }
    private func getMessage(data: Data) -> String? {
        var messageString = ""
        if let messageStringWithNulls = String(data: data, encoding: .ascii) {
            messageString = ""
            var done = false
            for char in messageStringWithNulls {
                if !done && char != "\0" {
                    messageString.append(char)
                } else {
                    done = true
                }
            }
            return messageString
        } else {
            return nil
        }
    }

    
    public func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        logger.trace("Readable Bytes \(buffer.readableBytes)")
        guard buffer.readableBytes > 0 else {
            return .needMoreData
        }
        guard let packetType = buffer.getBytes(at: buffer.readerIndex, length: 1)?.first else {
            return .needMoreData
        }
        guard let packetLength = PACKET_SIZES[Int(packetType)], packetLength > 0 else {
            logger.error("Warning: PacketAnalyzer.analyzeOnePacket received invalid packet type \(packetType)")
            throw NetrekError.invalidPacket
        }
        guard buffer.readableBytes >= packetLength else {
            return .needMoreData
        }
        guard let bytes = buffer.readBytes(length: packetLength) else {
            logger.error("\(#file) \(#function) Unexpected inability to copy \(packetLength) data")
            throw NetrekError.invalidPacket
        }
        let data = Data(bytes)
        switch packetType {
        case 1: // CP_MESSAGE
            let group = Int(data[1])
            let indiv = Int(data[2])
            _ = Int(data[3]) // pad1
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
                logger.debug("\(messageString)")
                //printData(data, success: true)
            } else {
                logger.error("PacketAnalyzer unable to decode message type 1")
                printData(data, success: false)
            }
            
            //messageString = NetrekMath.sanitizeString(messageString)
            guard let sender = universe.player(context: context) else {
                logger.error("Unable to identify message sender for context \(context)")
                return .continue
            }
            //TODO remove CRASHME
            /*if messageString == "crash34223" {
                var crashme: Double = Double.random(in: -5 ..< 5)
                let crash = UInt32(crashme)
            }*/
            if messageString == "reset34223" {
                universe.empireReset()
            }
            
            
            logger.debug("Received CP_MESSAGE 1 to group \(group) indiv \(indiv) message \(messageString) from \(sender.slot)")
            //let spMessage = MakePacket.spMessage(message: messageString, from: UInt8(sender.slot))
            
            switch group {
            case 8: // MALL
                let prefix = "\(sender.team.letter)\(sender.slot)->ALL: "
                let spMessage = MakePacket.spMessage(message: prefix + messageString, from: UInt8(sender.slot))
                for player in universe.players.filter({ $0.status != .free}) {
                    if let context = player.context {
                        context.eventLoop.execute {
                            let buffer = context.channel.allocator.buffer(bytes: spMessage)
                            _ = context.channel.write(buffer)
                        }
                    }
                    //player.connection?.send(data: spMessage)
                }
            case 4: // TEAM
                guard let destTeam = Team.allCases.filter({$0.rawValue == indiv}).first else {
                    logger.error("\(#file) \(#function) unable to identify team \(indiv)")
                    return .continue
                }
                let prefix = "\(sender.team.letter)\(sender.slot)->\(destTeam.prefix): "
                let spMessage = MakePacket.spMessage(message: prefix + messageString, from: UInt8(sender.slot))
                
                for player in universe.players.filter({ $0.status != .free && $0.team.rawValue == indiv}) {
                    if let context = player.context {
                        context.eventLoop.execute {
                            let buffer = context.channel.allocator.buffer(bytes: spMessage)
                            _ = context.channel.write(buffer)
                        }
                        //player.connection?.send(data: spMessage)
                    }
                }
            case 2: // INDIV
                
                guard let player = universe.players[safe: indiv], player.slot == indiv else {
                    logger.error("\(#file) \(#function) unable to identify player \(indiv)")
                    return .continue
                }
                let prefix = "\(sender.team.letter)\(sender.slot)->\(player.team.letter)\(player.slot): "
                let spMessage = MakePacket.spMessage(message: prefix + messageString, from: UInt8(sender.slot))
                if let context = player.context {
                    context.eventLoop.execute {
                        let buffer = context.channel.allocator.buffer(bytes: spMessage)
                        _ = context.channel.write(buffer)
                    }
                }
                //player.connection?.send(data: spMessage)
            default:
                logger.error("\(#file) \(#function) Unexpected group \(group)")
        }//switch group inside case 1
        
        case 2: //CP_SPEED 2
            //SP_PLAYER_INFO
            let speed = Int(data[1])
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_SPEED 2 speed \(speed)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for context \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.receivedCpSpeed(speed: speed)

        case 3: //CP_DIRECTION 3
            let direction = Int(data[1])
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            //universe.updatePlayer(playerID: playerID, kills: kills)
            logger.debug("Received CP_DIRECTION 3 direction \(direction)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for context \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.receivedCpDirection(netrekDirection: direction)
        case 4: //CP_LASER 4
            let direction = data[1]
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_LASER 4 direction \(direction)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.fireLaser(direction: direction)
        case 5: //CP_PLASMA 5
            let direction = Int(data[1])
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_PLASMA direction \(direction)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.firePlasma(direction: NetrekMath.directionNetrek2Radian(direction))
            //player.sendMessage(message: "Plasma torpedoes not implemented on this server")
            
        case 6: //CP_TORP 6
            let direction = data[1]
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_TORP 6 direction \(direction)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.fireTorpedo(direction: NetrekMath.directionNetrek2Radian(direction))

        case 7: //CP_QUIT 7
            _ = Int(data[1]) //pad1
            _ = Int(data[2]) //pad2
            _ = Int(data[3]) //pad3
            logger.debug("Received CP_QUIT 7")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            //player.sendMessage(message: "Goodbye!  Report issues to feedback@networkmom.net")
            player.receivedCpQuit()
            //player.reset()
            //_ = context.close()

        case 8: //CP_LOGIN 8  TODO NOT ENCRYPTED
            let query = Int(data[1])
            _ = Int(data[2]) //pad2
            _ = Int(data[3]) //pad3
            
            let nameRange = (4..<(4 + name_len))
            let nameData = data.subdata(in: nameRange)
            guard let name = getMessage(data: nameData) else {
                logger.error("CP LOGIN 8 Error unable to decode name from \(nameData)")
                return .continue
            }
            let passwordRange = (4 + name_len..<(4 + name_len * 2))
            let passwordData = data.subdata(in: passwordRange)
            guard let password = getMessage(data: passwordData) else {
                logger.error("CP LOGIN 8 Error unable to decode password")
                return .continue
            }
            let userinfoRange = (4 + name_len * 2..<(4 + name_len * 3))
            let userinfoData = data.subdata(in: userinfoRange)
            guard let userinfo = getMessage(data: userinfoData) else {
                logger.error("CP LOGIN 8 Error unable to decode login from \(userinfoData)")
                return .continue
            }
            logger.debug("Received CP_LOGIN 8 name \(name) userinfo \(userinfo)")
            if let player = universe.player(context: context) {
                player.receivedCpLogin(name: name, password: password, userinfo: userinfo)
            }
        case 9: // CP_OUTFIT 9
            let teamInt = Int(data[1])
            let shipInt = Int(data[2])
            _ = Int(data[3]) //pad1
            logger.debug("Received CP_OUTFIT 9 team \(teamInt) ship \(shipInt)")
            let team: Team
            switch teamInt {
            case 0:
                team = .federation
            case 1:
                team = .roman
            case 2:
                team = .kazari
            case 3:
                team = .orion
            default:
                logger.error("\(#file) \(#function) error received invalid teamInt \(teamInt)")
                return .continue
            }
            var shipOptional: ShipType? = nil
            
            for possibleShip in ShipType.allCases {
                if shipInt == possibleShip.rawValue {
                    shipOptional = possibleShip
                }
            }
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for context address \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            guard let ship = shipOptional else {
                logger.error("\(#file) \(#function) error received invalid ship type \(shipInt)")
                return .continue
            }
            _ = player.receivedCpOutfit(team: team, ship: ship)

        case 10: // CP_WAR
            let newmask = Int(data[1])
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_WAR 10 newmask \(newmask)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.sendMessage(message: "On this server, you are always at war")

        case 11: // CP_PRACTR
            _ = Int(data[1]) //pad1
            _ = Int(data[2]) //pad2
            _ = Int(data[3]) //pad3
            logger.debug("Received CP_PRACTR")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.sendMessage(message: "Practice robot not implemented")

        case 12: // CP_SHIELD
            let state = Int(data[1])
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_SHIELD 12 state \(state)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            if state == 1 {
                player.receivedCpShield(up: true)
                //player.shieldsUp = true
            } else {
                player.receivedCpShield(up: false)
                //player.shieldsUp = false
            }
            
        case 13: //CP_REPAIR
            let state = Int(data[1])
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_REPAIR 13 state \(state)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            if state == 1 {
                player.receivedRepair(true)
                player.sendMessage(message: "Damage control parties to all decks!")
            } else {
                player.receivedRepair(false)
                player.sendMessage(message: "Secure from damage control operations")
            }
            
        case 14: //CP_ORBIT
            let state = Int(data[1])
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_ORBIT 14 state \(state)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.enterOrbit()

        case 15: //CP_PLANLOCK 15
            let planetNum = Int(data[1])
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_PLANLOCK 15 planetNum \(planetNum)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.receivedPlanetLock(planetID: planetNum)

        case 16: //CP_PLAYLOCK 16
            let playerNum = Int(data[1])
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Recieved CP_PLAYLOCK 16 playerNum \(playerNum)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.receivedPlayerLock(playerID: playerNum)

        case 17: //CP_BOMB 17
            let state = Int(data[1])
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_BOMB 17 state \(state)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.receivedCpBomb()

        case 18: //CP_BEAM 18
            let state = Int(data[1]) //state 1 means beamup, 2 means beamdown
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_BEAM 18 state \(state)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            switch state {
            case 1:
                player.receivedCbBeam(up: true)
            case 2:
                player.receivedCbBeam(up: false)
            default:
                logger.error("\(#file) \(#function) error unexpected CP_BEAM state \(state)")
            }

        case 19: //CP_CLOAK 19
            let state = Int(data[1])
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_CLOAK 19 state \(state)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            if state == 1 {
                player.activateCloak(true)
            } else {
                player.activateCloak(false)
            }

        case 20: //CP_DET_TORPS 20
            _ = Int(data[1]) //pad1
            _ = Int(data[2]) //pad2
            _ = Int(data[3]) //pad3
            logger.debug("Received CP_DET_TORPS 20")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.receivedDetTorp()

        case 21: //CP_DET_MYTORP 21
            _ = Int(data[1]) //pad1
            let torpnum = Int(data.subdata(in: (2..<4)).to(type: UInt16.self).byteSwapped)
            logger.debug("Received CP_DET_MYTORP 21 torpnum \(torpnum)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.receivedDetMyTorp()

        case 22: //CP_COPILOT 22
            let state = Int(data[1])
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_COPILOT 22 state \(state)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_COPILOT not implemented on this server for connection \(context.remoteAddress?.description ?? "unknown")")
            player.sendMessage(message: "CP_COPILOT not implemented on this server")

        case 23: // CP_REFIT 23
            let ship = Int(data[1])
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_REFIT 23 ship \(ship)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_REFIT ship \(ship)")
            var newShipOptional: ShipType? = nil
            for shipType in ShipType.allCases {
                if shipType.rawValue == ship {
                    newShipOptional = shipType
                }
            }
            guard let newShip = newShipOptional else {
                player.sendMessage(message: "CP_REFIT error invalid ship type \(ship)")
                return .continue
            }
            player.receivedCpRefit(ship: newShip)

        case 24: // CP_TRACTOR 24
            let state = Int(data[1])
            let playerNum = Int(data[2])
            _ = Int(data[3]) //pad1
            logger.debug("Received CP_TRACTOR 24 state \(state) playerNum \(playerNum)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.receivedCpTractor(state: state, target: playerNum, mode: .tractor)
        
        case 25: // CP_REPRESS 25
            let state = Int(data[1])
            let playerNum = Int(data[2])
            _ = Int(data[3]) //pad1
            logger.debug("Received CP_REPRESS 25 state \(state) playerNum \(playerNum)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            player.receivedCpTractor(state: state, target: playerNum, mode: .pressor)
            
        case 26: // CP_COUP 26
            _ = Int(data[1]) //pad1
            _ = Int(data[2]) //pad2
            _ = Int(data[3]) //pad3
            logger.debug("Recieved CP_COUP 26")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_COUP not implemented on this server")
            player.sendMessage(message: "CP_COUP not implemented on this server")

        case 27: // CP_SOCKET 27
            let type = Int(data[1])
            let version = Int(data[2])
            let udpVersion = Int(data[3])
            let socket = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            logger.debug("Received CP_SOCKET 27 type \(type) version \(version) udpVersion \(udpVersion) socket \(socket)")
            universe.addPlayer(context: context)

        case 28: //CP_OPTIONS 28
            _ = Int(data[1]) //pad1
            _ = Int(data[2]) //pad2
            _ = Int(data[3]) //pad3
            let flags = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            let keymap = data.subdata(in: 8 ..< 8 + keymap_len)
            logger.debug("Received CP_OPTIONS 28 flags \(flags) plus keymap")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_OPTIONS not implemented on this server")
            player.sendMessage(message: "CP_OPTIONS not implemented on this server")

        case 29: //CP_BYE 29
            _ = Int(data[1]) //pad1
            _ = Int(data[2]) //pad2
            _ = Int(data[3]) //pad3
            logger.debug("Received CP_BYE 29")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_BYE received from player \(player.slot) \(context.remoteAddress?.description ?? "unknown")")
            player.sendMessage(message: "Goodbye!  Report issues to feedback@networkmom.net")
            player.flush()
            player.reset()
            _ = context.close()
            
        case 30: //CP_DOCKPERM 30
            let state = Int(data[1])
            _ = Int(data[2]) //pad2
            _ = Int(data[3]) //pad3
            logger.debug("Recieved CP_DOCKPERM 30 state \(state)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_DOCKPERM not implemented on this server")
            player.sendMessage(message: "CP_DOCKPERM not implemented on this server")

       case 31: //CP_UPDATES 31
           _ = Int(data[1]) //pad1
           _ = Int(data[2]) //pad2
           _ = Int(data[3]) //pad3
           let microseconds = Int(data.subdata(in: 4 ..< 8).to(type: UInt32.self).byteSwapped)
           //TODO we do nothing with CP_UPDATES
           /*logger.debug("Received CP_UPDATES 31 microseconds \(microseconds)")
           guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_UPDATES not implemented on this server")
            player.sendMessage(message: "CP_UPDATES not implemented on this server")*/

        case 32: //CP_RESETSTATS 32
            let verify = Int(data[1])
            _ = Int(data[2]) //pad2
            _ = Int(data[3]) //pad3
            logger.debug("Recieved CP_RESETSTATS verify \(verify)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_RESETSTATS not implemented on this server")
            player.sendMessage(message: "CP_RESETSTATS not implemented on this server")

        case 33: //CP_RESERVED 33
            _ = Int(data[1]) //pad1
            _ = Int(data[2]) //pad2
            _ = Int(data[3]) //pad3
            let reservedData = data.subdata(in: 4 ..< 4 + reserved_size)
            let reservedResponse = data.subdata(in: 4 + reserved_size ..< 4 + 2 * reserved_size)
            logger.debug("Received CP_RESERVED 33")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_RESERVED not implemented on this server")
            player.sendMessage(message: "CP_RESERVED not implemented on this server")

        case 34: //CP_SCAN 34
            let playerNum = Int(data[1])
            _ = Int(data[2]) //pad1
            _ = Int(data[3]) //pad2
            logger.debug("Received CP_SCAN 34 playerNum \(playerNum)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_SCAN not implemented on this server")
            player.sendMessage(message: "CP_SCAN not implemented on this server")

        case 35: //CP_UDP_REQ 35
            let request = Int(data[1])
            let connmode = Int(data[2])
            _ = Int(data[3]) //pad2
            let port = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            logger.debug("Received CP_UDP_REQ 35 request \(request) connmode \(connmode) port \(port)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_UDP_REQ not implemented on this server")
            player.sendMessage(message: "CP_UDP_REQ not implemented on this server")

        case 36: //CP_SEQUENCE 36 UDP only
            _ = Int(data[1]) //pad1
            let sequence = Int(data.subdata(in: (2..<4)).to(type: UInt16.self).byteSwapped)
            logger.debug("Received CP_SEQUENCE 36 sequence \(sequence)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_SEQUENCE not implemented on this server")
            player.sendMessage(message: "CP_SEQUENCE not implemented on this server")

        case 37: //CP_RSA_KEY 37
            _ = Int(data[1]) //pad1
            _ = Int(data[2]) //pad2
            _ = Int(data[3]) //pad3
            let global = data.subdata(in: (4 ..< 4 + key_size))
            let publicKey = data.subdata(in: (4 + key_size ..< 4 + key_size * 2))
            let response = data.subdata(in: 4 + key_size * 2 ..< 4 + key_size * 3)
            logger.debug("Received CP_RSA_KEY 37")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_RSA_KEY not implemented on this server")
            player.sendMessage(message: "CP_RSA_KEY not implemented on this server")

        case 38: //CP_PLANET 38
            let planetNum = Int(data[1])
            let owner = Int(data[2])
            let info = Int(data[3])
            let flags = Int(data.subdata(in: 4 ..< 6).to(type: UInt16.self).byteSwapped)
            let armies = Int(data.subdata(in: 6 ..< 10).to(type: UInt32.self).byteSwapped)  //TODO CHECK DECODE
            logger.debug("Received CP_PLANET 38 planetNum \(planetNum) owner \(owner) info \(info) flags \(flags) armies \(armies)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_PLANET not implemented on this server")
            player.sendMessage(message: "CP_PLANET not implemented on this server")
            
        case 42: //CP_PING
            let number = Int(data[1])
            let pingme = Int(data[2])
            _ = Int(data[3]) //pad1
            let sent = Int(data.subdata(in: 4 ..< 8).to(type: UInt32.self).byteSwapped)
            let received = Int(data.subdata(in: 8 ..< 12).to(type: UInt32.self).byteSwapped)
            logger.info("Received CP_PING pingme \(pingme) sent \(sent) received \(received)")

        case 43: //CP_S_REQ 43  Short request
            let request = Int(data[1])
            let version = Int(data[2])
            _ = Int(data[3]) //pad2
            logger.debug("Recived CP_SHORT_REQUEST 39 request \(request) version \(version)")
            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_SHORT_REQUEST not implemented on this server")
            player.sendMessage(message: "CP_SHORT_REQUEST not implemented on this server")

        case 44: //CP_SHORT_THRESHOLD 44
            _ = Int(data[1]) //pad1
            let threshold = Int(data.subdata(in: 2..<4).to(type: UInt16.self).byteSwapped)
            logger.debug("Received CP_SHORT_THRESHOLD threshold \(threshold)")

            guard let player = universe.player(context: context) else {
                logger.error("\(#file) \(#function) error unable to identify player for connection \(context.remoteAddress?.description ?? "unknown")")
                return .continue
            }
            logger.info("CP_SHORT_THRESHOLD not implemented on this server")
            player.sendMessage(message: "CP_SHORT_THRESHOLD not implemented on this server")

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
                
                //logger.trace(nameString)
                //printData(data, success: true)
            } else {
                logger.error("PacketAnalyzer unable to decode message type 60")
                printData(data, success: false)
            }
            //messageString = NetrekMath.sanitizeString(messageString)
            logger.debug("Received CP_FEATURE 60 type \(featureType) arg1 \(arg1) arg2 \(arg2) name \(nameString)")
            
        default:
            logger.error("Default case: Received packet type \(packetType) length \(packetLength)\n")
            let _ = buffer.readBytes(length: packetLength)
            printData(data, success: true)
        }//switch packetType
        return .continue
        
    }//func decode
}//class netrekServerDecoder
