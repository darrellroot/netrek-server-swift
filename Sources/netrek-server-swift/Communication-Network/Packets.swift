//
//  Packets.swift
//  NetrekServer
//
//  Created by Darrell Root on 6/19/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
// 

import Foundation

// SP_MESSAGE 1
struct SP_MESSAGE {
    var type: UInt8 = 1
    var flags: UInt8
    var recpt: UInt8 = 0 // not sure what this does
    var from: UInt8
    var message: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) =
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

    var size: Int {
        return 84
    }
}
// SP_PLAYER_INFO 2
struct SP_PLAYER_INFO {
    var type: UInt8 = 2
    var playerNum: UInt8
    var shipType: UInt8
    var team: UInt8
    
    var size: Int {
        return 4
    }
}

// SP_KILLS 3
struct SP_KILLS {
    var type: UInt8 = 3
    var playerNum: UInt8
    var pad1: UInt8 = 0
    var pad2: UInt8 = 0
    var kills: UInt32
    
    var size: Int {
        return 8
    }
}

// SP_PLAYER 4
struct SP_PLAYER {
    var type: UInt8 = 4
    var playerNum: UInt8
    var directionNetrek: UInt8
    var speed: UInt8
    var positionX: Int32
    var positionY: Int32
    
    var size: Int {
        return 12
    }
}

// SP_TORP_INFO 5 {
struct SP_TORP_INFO {
    var type: UInt8 = 5
    var war: UInt8 //mask of teams torp is hostile to
    var status: UInt8 // new status of torp, TFREE, TDET, etc
    var pad1: UInt8 = 0
    var torpedoNumber: UInt16
    var pad2: UInt16 = 0
    
    var size: Int {
        return 8
    }
    
    init(team: Team, status: TorpedoState, number: Int) {
        switch team {
            
        case .independent:
            self.war = UInt8(Team.federation.rawValue + Team.roman.rawValue + Team.kazari.rawValue + Team.orion.rawValue)
        case .federation:
            self.war = UInt8(Team.roman.rawValue + Team.kazari.rawValue + Team.orion.rawValue)

        case .roman:
            self.war = UInt8(Team.federation.rawValue + Team.kazari.rawValue + Team.orion.rawValue)

        case .kazari:
            self.war = UInt8(Team.federation.rawValue + Team.roman.rawValue + Team.orion.rawValue)

        case .orion:
            self.war = UInt8(Team.federation.rawValue + Team.roman.rawValue + Team.kazari.rawValue )

        case .ogg:
            self.war = UInt8(Team.federation.rawValue + Team.roman.rawValue + Team.kazari.rawValue + Team.orion.rawValue)
        }
        switch status {
            
        case .free:
            self.status = 0
        case .alive:
            self.status = 1
        case .explode:
            self.status = 2
        }
        self.torpedoNumber = UInt16(number).byteSwapped
    }
}
// SP_TORP 6
struct SP_TORP {
    var type: UInt8 = 6
    var direction: UInt8
    var torpedoNum: UInt16
    var positionX: UInt32
    var positionY: UInt32
    
    init(direction: UInt8, torpedoNum: Int, positionX: Int, positionY: Int) {
        self.direction = direction
        self.torpedoNum = UInt16(torpedoNum).byteSwapped
        if positionX >= 0 {
            self.positionX = UInt32(positionX).byteSwapped
        } else {
            self.positionX = 0
        }
        if positionY >= 0 {
            self.positionY = UInt32(positionY).byteSwapped
        } else {
            self.positionY = 0
        }
    }
    var size: Int {
        return 12
    }
}

// SP_PHASER 7
struct SP_LASER {
    var type: UInt8 = 7
    var laserID: UInt8
    var status: UInt8 // hit, miss?
    var direction: UInt8
    var positionX: UInt32
    var positionY: UInt32
    var target: UInt32
    
    init(laser: Laser) {
        self.laserID = UInt8(laser.laserID)
        self.status = laser.status.rawValue
        self.direction = NetrekMath.directionRadian2Netrek(laser.direction)
        self.positionX = UInt32(laser.positionX).byteSwapped
        self.positionY = UInt32(laser.positionY).byteSwapped
        if let target = laser.target {
            self.target = UInt32(target).byteSwapped
        } else {
            self.target = 255
        }
    }
    var size: Int {
        return 16
    }
}

// SP_MOTD 11
struct SP_MOTD {
    var type: UInt8 = 11
    var pad1: UInt8 = 0
    var pad2: UInt8 = 0
    var pad3: UInt8 = 0
    var motd: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) =
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

    var size: Int {
        return 84
    }
}
    
//SP_YOU 12
struct SP_YOU {
    var type: UInt8 = 12
    var playerNum: UInt8
    var hostile: UInt8
    var war: UInt8
    var armies: UInt8
    var tractor: UInt8
    var pad2: UInt8 = 0
    var pad3: UInt8 = 0
    var flags: UInt32
    var damage: UInt32
    var shield: UInt32
    var fuel: UInt32
    var etmp: UInt16
    var wtmp: UInt16
    var whydead: UInt16
    var whodead: UInt16
    
    init(player: Player) {
        self.playerNum = UInt8(player.slot)
        switch player.team {
            
        case .independent:
            //shoult not get here
            self.hostile = 1 + 2 + 4 + 8
            self.war = 1 + 2 + 4 + 8
        case .federation:
            self.hostile = 2 + 4 + 8
            self.war = 2 + 4 + 8
        case .roman:
            self.hostile = 1 + 4 + 8
            self.war = 1 + 4 + 8
        case .kazari:
            self.hostile = 1 + 2 + 8
            self.war = 1 + 2 + 8
        case .orion:
            self.hostile = 1 + 2 + 4
            self.war = 1 + 2 + 4
        case .ogg:
            //should not get here
            self.hostile = 1 + 2 + 4 + 8
            self.war = 1 + 2 + 4 + 8
        }
        self.armies = UInt8(player.armies)
        
        //legacy netrek server code adds 0x40 to the tractor number
        if let tractor = player.tractor {
            self.tractor = UInt8(tractor.slot + 0x40)
        } else {
            self.tractor = 0
        }
        //self.tractor = UInt8(player.tractor?.slot + 64 ?? 0)
        self.damage = UInt32(player.damage).byteSwapped
        self.shield = UInt32(player.shield).byteSwapped
        self.etmp = UInt16(player.etmp).byteSwapped
        self.wtmp = UInt16(player.wtmp).byteSwapped
        self.whydead = UInt16(player.whydead.rawValue).byteSwapped
        self.whodead = UInt16(player.whodead).byteSwapped
        self.fuel = UInt32(player.fuel).byteSwapped
        
        //TODO flags
        var flags: UInt32 = 0
        if player.shieldsUp { flags += 0x0001 }
        if player.repair { flags += 0x0002 }
        if player.bomb { flags += 0x0004 }
        if player.orbit != nil { flags += 0x008 }
        if player.cloak { flags += 0x010 }
        if player.weaponsOverheated { flags += 0x0020 }
        if player.enginesOverheated { flags += 0x0040 }
        switch player.transporter {
        case .beamup:
            flags += 0x0100
        case .beamdown:
            flags += 0x0200
        case .off:
            break
        }
        if player.selfDestruct { flags += 0x0400 }
        switch player.alertCondition {
        case .green:
            flags += 0x0800
        case .yellow:
            flags += 0x1000
        case .red:
            flags += 0x2000
        }
        if player.playerLock != nil {
            flags += 0x4000
        }
        if player.planetLock != nil {
            flags += 0x8000
        }
        if player.tractor != nil && player.tractorMode == .tractor { flags += 0x400000 }
        if player.tractor != nil && player.tractorMode == .pressor { flags += 0x800000 }
        debugPrint("SP_YOU flags \(flags)")
        self.flags = flags.byteSwapped
        // copilot 0x10000 not implemented
        // robot 0x40000 not implemented
        // dock 0x80000 not implemented
        // refit 0x100000 not implemented
        // refitting 0x200000 not implemented
        // dockok 0x1000000 not implemented
        // seen 0x2000000 not implemented
        // observe 0x8000000 not implemented
        // transwarm paradise 0x40000000 not implemented
        // bprobot 0x80000000 not implemented
    }
    var size: Int {
        return 32
    }
}
    
//SP_QUEUE 13
struct SP_QUEUE {
    var type: UInt8 = 13
    var pad1: UInt8 = 0
    var position: UInt16
    
    var size: Int {
        return 4
    }
}

//SP_PLANET 15
struct SP_PLANET {
    var type: UInt8 = 15
    var planetNum: UInt8
    var owner: UInt8
    var info: UInt8 = 0
    var flags: UInt16
    var pad2: UInt16 = 0
    var armies: UInt32
    
    init(planet: Planet) {
        self.planetNum = UInt8(planet.planetID)
        self.owner = UInt8(planet.team.rawValue)
        self.armies = UInt32(planet.armies).byteSwapped
        var flags: UInt16 = 0
        
        if planet.agri  {
            flags += PlanetFlags.agri.rawValue
        }
        if planet.fuel {
            flags += PlanetFlags.fuel.rawValue
        }
        if planet.repair {
            flags += PlanetFlags.repair.rawValue
        }
        self.flags = flags.byteSwapped
        self.info = planet.info
        
    }
    var size: Int {
        return 12
    }
    
}

//SP_PICKOK 16
struct SP_PICKOK {
    var type: UInt8 = 16
    var state: UInt8  // 0=no, 1=yes
    var pad1: UInt8 = 0
    var pad2: UInt8 = 0
    
    init(_ ok: Bool) {
        if ok {
            self.state = 1
        } else {
            self.state = 0
        }
    }
    var size: Int {
        return 4
    }
}
//SP_LOGIN 17
struct SP_LOGIN {
    var type: UInt8 = 17
    var accept: UInt8 //TODO 0 means login failed
    var paradise1: UInt8 = 0
    var paradise2: UInt8 = 0
    var flags: UInt32 = 0
    
    var keymap: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) =
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0)

    init(success: Bool) {
        if success {
            self.accept = 1
        } else {
            self.accept = 0
        }
    }
    var size: Int {
        return 104
    }
}
struct SP_FLAGS {
    var type: UInt8 = 18
    var playerID: UInt8
    var tractor: UInt8
    var pad1: UInt8 = 0
    var flags: UInt32
    
    init(player: Player) {
        self.playerID = UInt8(player.slot)
        var flags: UInt32 = 0
        if player.shieldsUp {
            flags += PlayerStatus.shield.rawValue
        }
        if player.cloak {
            flags += PlayerStatus.cloak.rawValue
        }
        self.tractor = UInt8(player.tractor?.slot ?? 0)
        self.flags = flags.byteSwapped
    }
    var size: Int {
        return 8
    }
}

struct SP_MASK {
    var type: UInt8 = 19
    var mask: UInt8
    var pad1: UInt8 = 0
    var pad2: UInt8 = 0
    
    var size: Int {
        return 4
    }
}

struct SP_PSTATUS {
    var type: UInt8 = 20
    var playerNum: UInt8
    var status: UInt8
    var pad1: UInt8 = 0
    
    var size: Int {
        return 4
    }
}


struct SP_HOSTILE {
    var type: UInt8 = 22
    var playerID: UInt8
    var war: UInt8
    var hostile: UInt8
    
    var size: Int {
        return 4
    }
}

struct SP_STATS {
    var type: UInt8 = 23
    var playerID: UInt8
    var pad1: UInt8 = 0
    var pad2: UInt8 = 0
    var tournamentKills: UInt32
    var tournamentLosses: UInt32
    var overallKills: UInt32
    var overallLosses: UInt32
    var tournamentTicks: UInt32
    var tournamentPlanets: UInt32
    var tournamentArmies: UInt32
    var starbaseKills: UInt32
    var starbaseLosses: UInt32
    var intramuralArmies: UInt32
    var intramuralPlanets: UInt32
    var maxKills100: UInt32
    var starbaseMaxKills100: UInt32
    
    init?(player: Player) {
        guard let user = player.user else {
            return nil
        }
        self.playerID = UInt8(player.slot)
        self.tournamentKills = UInt32(user.tKills).byteSwapped
        self.tournamentLosses = UInt32(user.tLosses).byteSwapped
        self.overallKills = UInt32(user.overallKills).byteSwapped
        self.overallLosses = UInt32(user.overallLosses).byteSwapped
        self.tournamentTicks = UInt32(user.tournamentTicks).byteSwapped
        self.tournamentPlanets = UInt32(user.tPlanets).byteSwapped
        self.tournamentArmies = UInt32(user.tArmies).byteSwapped
        self.starbaseKills = UInt32(user.sbKills).byteSwapped
        self.starbaseLosses = UInt32(user.sbLosses).byteSwapped
        self.intramuralArmies = UInt32(user.intramuralArmies).byteSwapped
        self.intramuralPlanets = UInt32(user.intramuralPlanets).byteSwapped
        self.maxKills100 = UInt32(user.maxKills * 100).byteSwapped
        self.starbaseMaxKills100 = UInt32(user.sbMaxKills * 100).byteSwapped
    }
    var size: Int {
        return 56
    }
}

struct SP_PL_LOGIN {
    var type: UInt8 = 24
    var playerNum: UInt8
    var rank: UInt8
    let pad1: UInt8 = 0
    var name: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    var monitor: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    var login: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    
    var size: Int {
        return 52
    }
}

// SP_PLANET_LOC 26
struct SP_PLANET_LOC {
    var type: UInt8 = 26
    var planetID: UInt8
    var pad1: UInt8 = 0
    var pad2: UInt8 = 0
    var positionX: Int32
    var positionY: Int32
    var name: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

    var size: Int {
        return 28
    }
}


