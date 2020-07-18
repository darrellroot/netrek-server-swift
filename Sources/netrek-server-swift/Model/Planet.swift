//
//  Planet.swift
//  NetrekServer
//
//  Created by Darrell Root on 6/24/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
// 

import Foundation

enum PlanetFlags: UInt16 {
    case repair = 0x010
    case fuel = 0x020
    case agri = 0x040
}

class Planet: Thing {
    
    var needsUpdate = false
    
    var positionX: Double { didSet { needsUpdate = true } }
    var positionY: Double { didSet { needsUpdate = true } }
    var repair = false { didSet { needsUpdate = true } }
    var fuel = false { didSet { needsUpdate = true } }
    var agri = false { didSet { needsUpdate = true } }
    var planetID: Int
    var name: String { didSet { needsUpdate = true } }
    var team: Team { didSet { needsUpdate = true } }
    let initialTeam: Team
    var homeworld: Bool { didSet { needsUpdate = true } }
    var armies = Int.random(in: 4 ..< 14) { didSet { needsUpdate = true } }
    var seen: [Team:Bool] = [:] { didSet { needsUpdate = true } }
    
    var info: UInt8 {
        var returnVal: UInt8 = 0
        for team in Team.allCases {
            if seen[team]! == true {
                returnVal += UInt8(team.rawValue)
            }
        }
        return returnVal
    }
    
    init(planetID: Int, positionX: Double, positionY: Double, name: String, team: Team, homeworld: Bool = false) {
        self.planetID = planetID
        self.positionX = positionX
        self.positionY = positionY
        self.name = name
        self.team = team
        self.initialTeam = team //used in empire mode when planet is indi
        self.homeworld = homeworld
        
        for team in Team.allCases {
            seen[team] = false
        }
        seen[self.team] = true
        
        if homeworld {
            self.fuel = true
            self.repair = true
        }
        if Int.random(in: 0 ..< 2) == 0 { self.fuel = true }
        if Int.random(in: 0 ..< 3) == 0 { self.repair = true }
        if Int.random(in: 0 ..< 4) == 0 {self.agri = true}
    }
    public func pop() {
        logger.debug("POP-Before planet \(self.name) armies \(armies)")
        //dont pop indi planets
        switch self.armies {
        case 0:
            return
        case 1 ..< 5:
            if Int.random(in: 0 ..< 20) == 0 {
                self.armies += 1
            }
            if Int.random(in: 0 ..< 10) == 0 {
                self.armies += Int.random(in: 1 ..< 3)
            }
            if self.agri {
                self.armies += 1
            }
        case 5 ..< 50:
            if Int.random(in: 0 ..< 10) == 0 {
                self.armies += Int.random(in: 1 ..< 3)
            }
            if self.agri && Int.random(in: 0 ..< 5) == 0 {
                self.armies += 1
            }
        default:
            return
        }
    }
    public func beamDownArmy(player: Player) {
        // player army already subtracted by calling function
        guard player.team != self.team else {
            self.armies += 1
            player.sendMessage(message: "Planet \(self.armies) armies.  Ship \(player.armies) armies.")
            return
        }
        switch self.armies {
        case 0:
            // planet captured
            self.team = player.team
            self.armies += 1
            player.kills += 0.25
            for player in universe.players.filter ({ $0.status != .free }) {
                player.sendMessage(message: "Planet \(self.name) captured by \(player.team.letter)\(player.slot.hex) \(player.user?.name ?? player.team.description)")
            }
            guard let user = player.user else {
                logger.error("\(#file) \(#function) unable to identify user for player \(player.slot)")
                return
            }
            //statistics only after this point
            switch universe.gameState {
            case .intramural:
                user.intramuralArmies += 1
                user.intramuralPlanets += 1
            case .tmode:
                user.tArmies += 1
                user.tPlanets += 1
            }
        case 1: //armies, will make indi
            self.team = .independent
            self.armies = 0
            player.kills += 0.02
            for player in universe.players.filter ({ $0.status != .free }) {
                player.sendMessage(message: "Planet \(self.name) destroyed by \(player.team.letter)\(player.slot.hex) \(player.user?.name ?? player.team.description)")
            }
            //statistics only
            guard let user = player.user else {
                logger.error("\(#file) \(#function) unable to identify user for player \(player.slot)")
                return
            }
            switch universe.gameState {
            case .intramural:
                user.intramuralArmies += 1
            case .tmode:
                user.tArmies += 1
            }
            return
        case 2...:
            self.armies -= 1
            player.kills += 0.02
            player.sendMessage(message: "Planet \(self.armies) armies.  Ship \(player.armies) armies.")
            //statistics only
            guard let user = player.user else {
                logger.error("\(#file) \(#function) unable to identify user for player \(player.slot)")
                return
            }
            switch universe.gameState {
            case .intramural:
                user.intramuralArmies += 1
            case .tmode:
                user.tArmies += 1
            }
            return
        default: // should not get here
            logger.error("\(#file) \(#function) unexpected planetary armies \(self.armies)")
            return
        }
    }
}
