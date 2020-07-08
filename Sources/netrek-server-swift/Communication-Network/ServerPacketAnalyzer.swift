//
//  PacketAnalyzer.swift
//  Netrek
//
//  Created by Darrell Root on 3/2/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
// 

/*
import Foundation
import AppKit
import Network
class ServerPacketAnalyzer {
    
    //let appDelegate = NSApplication.shared.delegate as! AppDelegate
    let universe: Universe
    var leftOverData: Data?
    
    let msg_len = 80
    let name_len = 16
    let keymap_len = 96
    let reserved_size = 16
    let key_size = 32
    let playerMax = 100 // we ignore player updates for more than this

    
    init(universe: Universe) {
        self.universe = universe
    }
    
    func analyze(incomingData: Data, connection: NWConnection) {
        //debugPrint("incoming data size \(incomingData.count) leftOverData.size \(String(describing: leftOverData?.count))")
        var data = Data()
        //debugPrint("one data.startIndex \(data.startIndex) data.endIndex \(data.endIndex)")
        
        if leftOverData != nil {
            //debugPrint("leftoverdata.startIndex \(leftOverData!.startIndex) leftoverdata.endIndex \(leftOverData!.endIndex)")
            //data.append(leftOverData!)
            var leftOverDataStruct: [UInt8] = []
            for byte in leftOverData! {
                leftOverDataStruct.append(byte)
            }
            //let leftOverDataStruct: [UInt8] = leftOverData!
            data = leftOverDataStruct + incomingData
            //debugPrint("two")
            //debugPrint("data startIndex \(data.startIndex) endIndex \(data.endIndex)\n")
            //debugPrint("incomingData startIndex \(incomingData.startIndex) endIndex \(incomingData.endIndex)\n")

            //data.append(incomingData)
            //debugPrint("three")
            self.leftOverData = nil
        } else {
            //debugPrint("four")
            data = incomingData
        }
        //debugPrint("done copying data")
        repeat {
            guard let packetType: UInt8 = data.first else {
                debugPrint("PacketAnalyzer.analyze is done, should not have gotten here")
                //appDelegate.reader?.receive()
                return
            }
            guard let packetLength = PACKET_SIZES[Int(packetType)] else {
                debugPrint("Warning: PacketAnalyzer.analyze received invalid packet type \(packetType) dumping data")
                printData(data, success: false)
                return
            }
            guard packetLength > 0 else {
                debugPrint("PacketAnalyzer invalid packet length \(packetLength) type \(packetType)")
                printData(data, success: false)
                return
            }
            guard data.count >= packetLength else {
                debugPrint("PacketAnalyzer.analyze: fractional packet expected length \(packetLength) remaining size \(data.count) saving for next round")
                self.leftOverData = Data()
                for byte in data {
                    self.leftOverData?.append(byte)
                }
                //self.leftOverData!.append(data)
                //debugPrint("created leftOverData startIndex \(leftOverData?.startIndex) endIndex \(leftOverData?.endIndex)")
                //debugPrint("from data startIndex \(data.startIndex) endIndex \(data.endIndex)")

                return
            }
            let range = (data.startIndex..<data.startIndex + packetLength)
            //debugPrint("packetAnalyzer.analyze startIndex \(data.startIndex) packetLength \(packetLength) endindex \(data.endIndex) packetType \(packetType)")
            let thisPacket = data.subdata(in: range)
            self.analyzeOnePacket(data: thisPacket, connection: connection)
            data.removeFirst(packetLength)
        } while data.count > 0
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
    func analyzeOnePacket(data: Data, connection: NWConnection) {
        //debugPrint("in analyze one packet")
        guard data.count > 0 else {
            debugPrint("PacketAnalyer.analyzeOnePacket data length 0")
            return
        }
        let packetType: UInt8 = data[0]
        //debugPrint("in analyze one packet packetType \(packetType)")
        guard let packetLength = PACKET_SIZES[Int(packetType)] else {
            debugPrint("Warning: PacketAnalyzer.analyzeOnePacket received invalid packet type \(packetType)")
            printData(data, success: false)
            return
        }
        guard packetLength > 0 else {
            debugPrint("PacketAnalyzer.analyzeOnePacket invalid packet length \(packetLength) type \(packetType)")
            printData(data, success: false)
            return
        }
        guard packetLength == data.count else {
            debugPrint("PacketAnalyzer.analyeOnePacket unexpected data length \(data.count) expected \(packetLength) type \(packetType)")
            printData(data, success: false)
            return
        }
        switch packetType {
            
        case 1: // CP_MESSAGE
            let group = Int(data[1])
            let indiv = Int(data[2])
            let pad1 = Int(data[3])
            let range = (4..<(4 + msg_len))
            let messageData = data.subdata(in: range)
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
            guard let sender = universe.player(connection: connection) else {
                debugPrint("Unable to identify message sender for connection \(connection)")
                return
            }
            

            debugPrint("Received CP_MESSAGE 1 to group \(group) indiv \(indiv) message \(messageString) from \(sender.slot)")
            //let spMessage = MakePacket.spMessage(message: messageString, from: UInt8(sender.slot))

            switch group {
            case 8: // MALL
                let prefix = "\(sender.team.letter)\(sender.slot)->ALL: "
                let spMessage = MakePacket.spMessage(message: prefix + messageString, from: UInt8(sender.slot))
                for player in universe.players.filter({ $0.status != .free}) {
                    player.connection?.send(data: spMessage)
                }
            case 4: // TEAM
                guard let destTeam = Team.allCases.filter({$0.rawValue == indiv}).first else {
                    debugPrint("\(#file) \(#function) unable to identify team \(indiv)")
                    return
                }
                let prefix = "\(sender.team.letter)\(sender.slot)->\(destTeam.prefix): "
                let spMessage = MakePacket.spMessage(message: prefix + messageString, from: UInt8(sender.slot))

                for player in universe.players.filter({ $0.status != .free && $0.team.rawValue == indiv}) {
                    player.connection?.send(data: spMessage)
                }
            case 2: // INDIV

                guard let player = universe.players[safe: indiv], player.slot == indiv else {
                    debugPrint("\(#file) \(#function) unable to identify player \(indiv)")
                    return
                }
                let prefix = "\(sender.team.letter)\(sender.slot)->\(player.team.letter)\(player.slot): "
                let spMessage = MakePacket.spMessage(message: prefix + messageString, from: UInt8(sender.slot))
                player.connection?.send(data: spMessage)
            default:
                debugPrint("\(#file) \(#function) Unexpected group \(group)")
            }
        case 2: //CP_SPEED 2
            //SP_PLAYER_INFO
            let speed = Int(data[1])
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_SPEED 2 speed \(speed)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.receivedCpSpeed(speed: speed)
            
            //universe.updatePlayer(playerID: playerID, shipType: shipType, team: team)
       
        case 3: //CP_DIRECTION 3
            let direction = Int(data[1])
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            //universe.updatePlayer(playerID: playerID, kills: kills)
            debugPrint("Received CP_DIRECTION 3 direction \(direction)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.receivedCpDirection(netrekDirection: direction)

        case 4: //CP_LASER 4
            let direction = data[1]
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_LASER 4 direction \(direction)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.fireLaser(direction: direction)

        case 5: //CP_PLASMA 5
            let direction = Int(data[1])
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_PLASMA direction \(direction)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.sendMessage(message: "Plasma torpedoes not implemented on this server")
        
        case 6: //CP_TORP 6
            let direction = data[1]
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_TORP 6 direction \(direction)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.fireTorpedo(direction: NetrekMath.directionNetrek2Radian(direction))

        case 7: //CP_QUIT 7
            let pad1 = Int(data[1])
            let pad2 = Int(data[2])
            let pad3 = Int(data[3])
            debugPrint("Received CP_QUIT 7")
            
        case 8: //CP_LOGIN 8  TODO NOT ENCRYPTED
            let query = Int(data[1])
            let pad2 = Int(data[2])
            let pad3 = Int(data[3])
            
            let nameRange = (4..<(4 + name_len))
            let nameData = data.subdata(in: nameRange)
            guard let name = getMessage(data: nameData) else {
                debugPrint("CP LOGIN 8 Error unable to decode name fro \(nameData)")
                return
            }
            let passwordRange = (4 + name_len..<(4 + name_len * 2))
            let passwordData = data.subdata(in: passwordRange)
            guard let password = getMessage(data: passwordData) else {
                debugPrint("CP LOGIN 8 Error unable to decode password")
                return
            }
            let userinfoRange = (4 + name_len * 2..<(4 + name_len * 3))
            let userinfoData = data.subdata(in: userinfoRange)
            guard let userinfo = getMessage(data: userinfoData) else {
                debugPrint("CP LOGIN 8 Error unable to decode login from \(userinfoData)")
                return
            }
            debugPrint("Received CP_LOGIN 8 name \(name) userinfo \(userinfo)")
            if let player = universe.player(connection: connection) {
                player.receivedCpLogin(name: name, password: password, userinfo: userinfo)
            }
            
        case 9: // CP_OUTFIT 9
            let teamInt = Int(data[1])
            let shipInt = Int(data[2])
            let pad1 = Int(data[3])
            debugPrint("Received CP_OUTFIT 9 team \(teamInt) ship \(shipInt)")
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
                debugPrint("\(#file) \(#function) error received invalid teamInt \(teamInt)")
                return
            }
            var shipOptional: ShipType? = nil
            
            for possibleShip in ShipType.allCases {
                if shipInt == possibleShip.rawValue {
                    shipOptional = possibleShip
                }
            }
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            guard let ship = shipOptional else {
                debugPrint("\(#file) \(#function) error received invalid ship type \(shipInt)")
                return
            }
            player.receivedCpOutfit(team: team, ship: ship)
                
        case 10: // CP_WAR
            let newmask = Int(data[1])
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_WAR 10 newmask \(newmask)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.sendMessage(message: "On this server, you are always at war")

        case 11: // CP_PRACTR
            let pad1 = Int(data[1])
            let pad2 = Int(data[2])
            let pad3 = Int(data[3])
            debugPrint("Received CP_PRACTR")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.sendMessage(message: "Practice robot not implemented")
            
        case 12: // CP_SHIELD
            let state = Int(data[1])
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_SHIELD 12 state \(state)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            if state == 1 {
                player.shieldsUp = true
            } else {
                player.shieldsUp = false
            }
            
        case 13: //CP_REPAIR
            let state = Int(data[1])
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_REPAIR 13 state \(state)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
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
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_ORBIT 14 state \(state)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.enterOrbit()

        case 15: //CP_PLANLOCK 15
            let planetNum = Int(data[1])
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_PLANLOCK 15 planetNum \(planetNum)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.receivedPlanetLock(planetID: planetNum)
            
        case 16: //CP_PLAYLOCK 16
            let playerNum = Int(data[1])
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Recieved CP_PLAYLOCK 16 playerNum \(playerNum)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.receivedPlayerLock(playerID: playerNum)

        case 17: //CP_BOMB 17
            let state = Int(data[1])
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_BOMB 17 state \(state)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.receivedCpBomb()
            
        case 18: //CP_BEAM 18
            let state = Int(data[1]) //state 1 means beamup, 2 means beamdown
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_BEAM 18 state \(state)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            switch state {
            case 1:
                player.receivedCbBeam(up: true)
            case 2:
                player.receivedCbBeam(up: false)
            default:
                debugPrint("\(#file) \(#function) error unexpected CP_BEAM state \(state)")
            }
            
        case 19: //CP_CLOAK 19
            let state = Int(data[1])
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_CLOAK 19 state \(state)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            if state == 1 {
                player.activateCloak(true)
            } else {
                player.activateCloak(false)
            }
            
        case 20: //CP_DET_TORPS 20
            let pad1 = Int(data[1])
            let pad2 = Int(data[2])
            let pad3 = Int(data[3])
            debugPrint("Received CP_DET_TORPS 20")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.receivedDetTorp()
            
        case 21: //CP_DET_MYTORP 21
            let pad1 = Int(data[1])
            let torpnum = Int(data.subdata(in: (2..<4)).to(type: UInt16.self).byteSwapped)
            debugPrint("Received CP_DET_MYTORP 21 torpnum \(torpnum)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.receivedDetMyTorp()
            
        case 22: //CP_COPILOT 22
            let state = Int(data[1])
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_COPILOT 22 state \(state)")
            
        case 23: // CP_REFIT 23
            let ship = Int(data[1])
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_REFIT 23 ship \(ship)")
            
        case 24: // CP_TRACTOR 24
            let state = Int(data[1])
            let playerNum = Int(data[2])
            let pad1 = Int(data[3])
            debugPrint("Received CP_TRACTOR 24 state \(state) playerNum \(playerNum)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.receivedCpTractor(state: state, target: playerNum, mode: .tractor)
            
        case 25: // CP_REPRESS 25
            let state = Int(data[1])
            let playerNum = Int(data[2])
            let pad1 = Int(data[3])
            debugPrint("Received CP_REPRESS 25 state \(state) playerNum \(playerNum)")
            guard let player = universe.player(connection: connection) else {
                debugPrint("\(#file) \(#function) error unable to identify player for connection \(connection.endpoint)")
                return
            }
            player.receivedCpTractor(state: state, target: playerNum, mode: .pressor)

        case 26: // CP_COUP 26
            let pad1 = Int(data[1])
            let pad2 = Int(data[2])
            let pad3 = Int(data[3])
            debugPrint("Recieved CP_COUP 26")
        
        case 27: // CP_SOCKET 27
            let type = Int(data[1])
            let version = Int(data[2])
            let udpVersion = Int(data[3])
            let socket = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            debugPrint("Received CP_SOCKET 27 type \(type) version \(version) udpVersion \(udpVersion) socket \(socket)")
            
        case 28: //CP_OPTIONS 28
            let pad1 = Int(data[1])
            let pad2 = Int(data[2])
            let pad3 = Int(data[3])
            let flags = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            let keymap = data.subdata(in: 8 ..< 8 + keymap_len)
            debugPrint("Received CP_OPTIONS 28 flags \(flags) plus keymap")
        
        case 29: //CP_BYE 29
            let pad1 = Int(data[1])
            let pad2 = Int(data[2])
            let pad3 = Int(data[3])
            debugPrint("Received CP_BYE 29")
            
        case 30: //CP_DOCKPERM 30
            let state = Int(data[1])
            let pad2 = Int(data[2])
            let pad3 = Int(data[3])
            debugPrint("Recieved CP_DOCKPERM 30 state \(state)")
            
        case 31: //CP_UPDATES 31
            let pad1 = Int(data[1])
            let pad2 = Int(data[2])
            let pad3 = Int(data[3])
            let microseconds = Int(data.subdata(in: 4 ..< 8).to(type: UInt32.self).byteSwapped)
            //TODO we do nothing with CP_UPDATES
            debugPrint("Received CP_UPDATES 31 microseconds \(microseconds)")
            
        case 32: //CP_RESETSTATS 32
            let verify = Int(data[1])
            let pad2 = Int(data[2])
            let pad3 = Int(data[3])
            debugPrint("Recieved CP_RESETSTATS verify \(verify)")
            
        case 33: //CP_RESERVED 33
            let pad1 = Int(data[1])
            let pad2 = Int(data[2])
            let pad3 = Int(data[3])
            let reservedData = data.subdata(in: 4 ..< 4 + reserved_size)
            let reservedResponse = data.subdata(in: 4 + reserved_size ..< 4 + 2 * reserved_size)
            debugPrint("Received CP_RESERVED 33")
        
        case 34: //CP_SCAN 34
            let playerNum = Int(data[1])
            let pad1 = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Received CP_SCAN 34 playerNum \(playerNum)")
            
        case 35: //CP_UDP_REQ 35
            let request = Int(data[1])
            let connmode = Int(data[2])
            let pad2 = Int(data[3])
            let port = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            debugPrint("Received CP_IDP_REQ 35 request \(request) connmode \(connmode) port \(port)")

        case 36: //CP_SEQUENCE 36 UDP only
            let pad1 = Int(data[1])
            let sequence = Int(data.subdata(in: (2..<4)).to(type: UInt16.self).byteSwapped)
            debugPrint("Received CP_SEQUENCE 36 sequence \(sequence)")
            
        case 37: //CP_RSA_KEY 37
            let pad1 = Int(data[1])
            let pad2 = Int(data[2])
            let pad3 = Int(data[3])
            let global = data.subdata(in: (4 ..< 4 + key_size))
            let publicKey = data.subdata(in: (4 + key_size ..< 4 + key_size * 2))
            let response = data.subdata(in: 4 + key_size * 2 ..< 4 + key_size * 3)
            debugPrint("Received CP_RSA_KEY 37")

        case 38: //CP_PLANET 38
            let planetNum = Int(data[1])
            let owner = Int(data[2])
            let info = Int(data[3])
            let flags = Int(data.subdata(in: 4 ..< 6).to(type: UInt16.self).byteSwapped)
            let armies = Int(data.subdata(in: 6 ..< 10).to(type: UInt32.self).byteSwapped)  //TODO CHECK DECODE
            debugPrint("Received CP_PLANET 38 planetNum \(planetNum) owner \(owner) info \(info) flags \(flags) armies \(armies)")
        
        case 43: //CP_S_REQ 43  Short request
            let request = Int(data[1])
            let version = Int(data[2])
            let pad2 = Int(data[3])
            debugPrint("Recived CP_SHORT_REQUEST 39 request \(request) version \(version)")
            
        case 44: //CP_SHORT_THRESHOLD 44
            let pad1 = Int(data[1])
            let threshold = Int(data.subdata(in: 2..<4).to(type: UInt16.self).byteSwapped)
            debugPrint("Received CP_SHORT_THRESHOLD threshold \(threshold)")
        
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
            printData(data, success: true)

        }
    }
    func printFlags(flags: UInt32) {
        var flags = flags
        for bit in 0..<32 {
            let thisFlag = flags & 0x01
            debugPrint("bit \(bit) flag \(thisFlag)\n")
            flags = flags >> 1
        }
    }
}
 */
