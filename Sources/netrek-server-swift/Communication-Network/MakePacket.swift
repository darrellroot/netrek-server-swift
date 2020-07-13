//
//  MakePacket.swift
//  NetrekServer
//
//  Created by Darrell Root on 6/19/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
// 

import Foundation

class MakePacket {
    static let message_length = 80
    
    static func make16Tuple(string: String) -> (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) {
        var temp: [UInt8] = []
        for _ in 0..<16 {
            temp.append(0)
        }
        for (index,char) in string.utf8.enumerated() {
            if index < 15 {
                // leaving last position with null
                temp[index] = char
            }
        }
        let information = (temp[0],temp[1],temp[2],temp[3],temp[4],temp[5],temp[6],temp[7],temp[8],temp[9],temp[10],temp[11],temp[12],temp[13],temp[14],temp[15])
        return information
    }
    // SP_MESSAGE 1
    static func spMessage(message: String, from: UInt8)
        -> Data {
            //from 255 = god, otherwise from player
        let message_length = 80
        var packet = SP_MESSAGE(flags: 0, from: from)
        withUnsafeMutablePointer(to: &packet.message) {
            $0.withMemoryRebound(to: UInt8.self, capacity: message_length) {mesg_ptr in
                for count in 0 ..< message_length {
                    mesg_ptr[count] = 0
                }
                var count = 0
                for char in message.utf8 {
                    if count < message_length - 1 {
                        mesg_ptr[count] = char
                        count = count + 1
                    }
                }
                for count2 in count ..< message_length {
                    mesg_ptr[count2] = 0
                }
            }
        }
        let data = Data(bytes: &packet, count: message_length + 4)
        debugPrint("Sending SP_MESSAGE 1 message \(message)")
        return data
    }

    
    // SP_PLAYER_INFO 2
    static func spPlayerInfo(player: Player) -> Data {
        var packet = SP_PLAYER_INFO(playerNum: UInt8(player.slot), shipType: UInt8(player.ship.rawValue), team: UInt8(player.team.rawValue))
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    
    // SP_KILLS 3
    static func spKills(player: Player) -> Data {
        let kills = UInt32(player.kills * 100).byteSwapped
        var packet = SP_KILLS(playerNum: UInt8(player.slot), kills: kills)
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    
    // SP_PLAYER 4
    static func spPlayer(player: Player) -> Data {
        let positionX = Int32(player.positionX).byteSwapped
        let positionY = Int32(player.positionY).byteSwapped
        
        var packet = SP_PLAYER(playerNum: UInt8(player.slot), directionNetrek: UInt8(player.directionNetrek), speed: UInt8(player.speed), positionX: positionX, positionY: positionY)
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    
    //SP_TORP_INFO 5
    static func spTorpInfo(torpedo: Torpedo) -> Data {
        var packet = SP_TORP_INFO(team: torpedo.team, status: torpedo.state, number: torpedo.number)
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    
    //SP_TORP 6
    static func spTorp(torpedo: Torpedo) -> Data {
        var packet = SP_TORP(direction: UInt8(torpedo.directionNetrek), torpedoNum: torpedo.number, positionX: Int(torpedo.positionX), positionY: Int(torpedo.positionY))
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    //SP_LASER 7
    static func spLaser(laser: Laser) -> Data {
        var packet = SP_LASER(laser: laser)
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    //SP_PLASMA_INFO 8
    static func spPlasmaInfo(plasma: Plasma) -> Data {
        var packet = SP_PLASMA_INFO(team: plasma.team, status: plasma.state, number: plasma.number)
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }

    //SP_PLASMA 9
    static func spPlasma(plasma: Plasma) -> Data {
        var packet = SP_PLASMA(direction: UInt8(plasma.directionNetrek), plasmaNum: plasma.number, positionX: Int(plasma.positionX), positionY: Int(plasma.positionY))
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }

    // SP_MOTD 11
    static func spMotd(motd: String) -> Data {
        var packet = SP_MOTD()
        withUnsafeMutablePointer(to: &packet.motd) {
            $0.withMemoryRebound(to: UInt8.self, capacity: message_length) {mesg_ptr in
                for count in 0 ..< message_length {
                    mesg_ptr[count] = 0
                }
                var count = 0
                for char in motd.utf8 {
                    if count < message_length - 1 {
                        mesg_ptr[count] = char
                        count = count + 1
                    }
                }
                for count2 in count ..< message_length {
                    mesg_ptr[count2] = 0
                }
            }
        }
        let data = Data(bytes: &packet, count: message_length + 4)
        debugPrint("Sending SP_MOTD 11 motd \(motd)")
        return data

    }
    
    //SP_YOU 12
    static func spYou(player: Player) -> Data {
        var packet = SP_YOU(player: player)
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    
    //SP_QUEUE 13
    /*static func spQueue(player: Player, universe: Universe) -> Data {
        var position = 0
        let myPlayerNum = player.playerNum
        if player.playerNum < 32 {
            debugPrint("\(#file) \(#function) Unexpected error playerNum < 32 \(player.playerNum)")
            position = 0
        }
        for otherPlayer in universe.players {
            if otherPlayer.playerNum >= 32 && otherPlayer.playerNum < myPlayerNum {
                position += 1
            }
        }
        var packet = SP_QUEUE(position: UInt16(position))
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }*/
    
    //SP_PLANET 15
    static func spPlanet(planet: Planet) -> Data {
        var packet = SP_PLANET(planet: planet)
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    
    //SP_PICKOK 16
    static func spPickOk(_ ok: Bool) -> Data {
        var packet = SP_PICKOK(ok)
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    //SP_LOGIN 17
    static func spLogin(success: Bool) -> Data {
        var packet = SP_LOGIN(success: success)
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    //SP_FLAGS 18
    static func spFlags(player: Player) -> Data {
        /*var flags: UInt32 = 0
        if player.shieldsUp {
            flags += PlayerStatus.shield.rawValue
        }
        if player.cloak {
            flags += PlayerStatus.cloak.rawValue
        }*/
        var packet = SP_FLAGS(player: player)
        //var packet = SP_FLAGS(playerID: UInt8(player.slot), tractor: UInt8(player.tractor ?? 0), flags: flags)
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    
    //SP_MASK 19
    static func spMask(universe: Universe) -> Data {
        let team1 = universe.team1
        let team2 = universe.team2
        var totalTeam1 = 0
        var totalTeam2 = 0
        var mask = 0
        for player in universe.players {
            if player.status == .alive && player.team == team1 {
                totalTeam1 += 1
            }
            if player.status == .alive && player.team == team2 {
                totalTeam2 += 1
            }
        }
        if totalTeam1 <= totalTeam2 {
            mask += team1.rawValue
        }
        if totalTeam2 <= totalTeam1 {
            mask += team2.rawValue
        }
        var packet = SP_MASK(mask: UInt8(mask))
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    
    //SP_PSTATUS 20
    static func spPStatus(player: Player) -> Data {
        var packet = SP_PSTATUS(playerNum: UInt8(player.slot), status: UInt8(player.status.rawValue))
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }

    
    //SP_HOSTILE 22
    static func spHostile(player: Player) -> Data {
        let hostile: UInt8
        switch player.team {
            //for now all other teams are hostile
            //TODO implement WAR logic
        case .independent:
            hostile = UInt8(Team.federation.rawValue + Team.roman.rawValue + Team.kazari.rawValue + Team.orion.rawValue + Team.ogg.rawValue)
        case .federation:
            hostile = UInt8(Team.roman.rawValue + Team.kazari.rawValue + Team.orion.rawValue + Team.ogg.rawValue)

        case .roman:
            hostile = UInt8(Team.federation.rawValue + Team.kazari.rawValue + Team.orion.rawValue + Team.ogg.rawValue)

        case .kazari:
            hostile = UInt8(Team.federation.rawValue + Team.roman.rawValue + Team.orion.rawValue + Team.ogg.rawValue)
        case .orion:
            hostile = UInt8(Team.federation.rawValue + Team.roman.rawValue + Team.kazari.rawValue + Team.ogg.rawValue)

        case .ogg:
            hostile = UInt8(Team.federation.rawValue + Team.roman.rawValue + Team.kazari.rawValue + Team.orion.rawValue)

        }
        var packet = SP_HOSTILE(playerID: UInt8(player.slot), war: hostile, hostile: hostile)
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    
    //SP_STATS 23
    static func spStats(player: Player) -> Data? {
        guard var packet = SP_STATS(player: player) else {
            return nil
        }
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    
    //SP_PL_LOGIN 24
    static func spPlLogin(player: Player) -> Data {
        var packet = SP_PL_LOGIN(playerNum: UInt8(player.slot), rank: UInt8(player.user?.rank.value ?? 0))
        packet.name = make16Tuple(string: player.user?.name ?? "")
        packet.monitor = make16Tuple(string: "")
        packet.login = make16Tuple(string: player.user?.userinfo ?? "")
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    
    // SP_PLANET_LOC 26
    static func spPlanetLoc(planet: Planet) -> Data {
        var packet = SP_PLANET_LOC(planetID: UInt8(planet.planetID), positionX: Int32(planet.positionX).byteSwapped, positionY: Int32(planet.positionY).byteSwapped)
        packet.name = make16Tuple(string: planet.name)
        let data = Data(bytes: &packet, count: packet.size)
        return data
    }
    
    
}
