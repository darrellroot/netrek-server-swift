//
//  ServerUniverse.swift
//  NetrekServer
//
//  Created by Darrell Root on 5/31/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
// 

import Foundation
//import Network
import NIO

class Universe {
    
    let updatesPerSecond = 20.0
    var timer: Timer?
    //var weakTimer: Timer? = nil
    
    var timerCount = 0
    
    static let startPlanets = [
        Planet(planetID: 0, positionX: 20000, positionY: 80000, name: "Earth", team: .federation, homeworld: true),
        Planet(planetID: 1, positionX: 10000, positionY: 60000, name: "Rigel", team: .federation, homeworld: false),
        Planet(planetID: 2, positionX: 25000, positionY: 60000, name: "Canopus", team: .federation, homeworld: false),
        Planet(planetID: 3, positionX: 44000, positionY: 81000, name: "Beta Crucis", team: .federation, homeworld: false),
        Planet(planetID: 4, positionX: 39000, positionY: 55000, name: "Organia", team: .federation, homeworld: false),
        Planet(planetID: 5, positionX: 30000, positionY: 90000, name: "Deneb", team: .federation, homeworld: false),
        Planet(planetID: 6, positionX: 45000, positionY: 66000, name: "Ceti Alpha V", team: .federation, homeworld: false),
        Planet(planetID: 7, positionX: 11000, positionY: 75000, name: "Altair", team: .federation, homeworld: false),
        Planet(planetID: 8, positionX: 8000, positionY: 93000, name: "Vega", team: .federation, homeworld: false),
        Planet(planetID: 9, positionX: 32000, positionY: 74000, name: "Alpha Centauri", team: .federation, homeworld: false),
        Planet(planetID: 10, positionX: 20000, positionY: 20000, name: "Rome", team: .roman, homeworld: true),
        Planet(planetID: 11, positionX: 45000, positionY: 7000, name: "Eridani", team: .roman, homeworld: false),
        Planet(planetID: 12, positionX: 4000, positionY: 12000, name: "Aldeberan", team: .roman, homeworld: false),
        Planet(planetID: 13, positionX: 42000, positionY: 44000, name: "Regulus", team: .roman, homeworld: false),
        Planet(planetID: 14, positionX: 13000, positionY: 45000, name: "Capella", team: .roman, homeworld: false),
        Planet(planetID: 15, positionX: 28000, positionY: 8000, name: "Tauri", team: .roman, homeworld: false),
        Planet(planetID: 16, positionX: 28000, positionY: 23000, name: "Draconis", team: .roman, homeworld: false),
        Planet(planetID: 17, positionX: 40000, positionY: 25000, name: "Sirius", team: .roman, homeworld: false),
        Planet(planetID: 18, positionX: 25000, positionY: 44000, name: "Indi", team: .roman, homeworld: false),
        Planet(planetID: 19, positionX: 8000, positionY: 29000, name: "Hydrae", team: .roman, homeworld: false),
        Planet(planetID: 20, positionX: 80000, positionY: 20000, name: "Kazari", team: .kazari, homeworld: true),
        Planet(planetID: 21, positionX: 70000, positionY: 40000, name: "Pliedes V", team: .kazari, homeworld: false),
        Planet(planetID: 22, positionX: 60000, positionY: 10000, name: "Andromeda", team: .kazari, homeworld: false),
        Planet(planetID: 23, positionX: 56400, positionY: 38200, name: "Lalande", team: .kazari, homeworld: false),
        Planet(planetID: 24, positionX: 91120, positionY: 9320, name: "Praxis", team: .kazari, homeworld: false),
        Planet(planetID: 25, positionX: 89960, positionY: 31760, name: "Lyrae", team: .kazari, homeworld: false),
        Planet(planetID: 26, positionX: 70720, positionY: 26320, name: "Scorpii", team: .kazari, homeworld: false),
        Planet(planetID: 27, positionX: 83600, positionY: 45400, name: "Mira", team: .kazari, homeworld: false),
        Planet(planetID: 28, positionX: 54600, positionY: 22600, name: "Cygni", team: .kazari, homeworld: false),
        Planet(planetID: 29, positionX: 73080, positionY: 6640, name: "Achernar", team: .kazari, homeworld: false),
        Planet(planetID: 30, positionX: 80000, positionY: 80000, name: "Orion", team: .orion, homeworld: true),
        Planet(planetID: 31, positionX: 91200, positionY: 56600, name: "Cassiopeia", team: .orion, homeworld: false),
        Planet(planetID: 32, positionX: 70800, positionY: 54200, name: "El Nath", team: .orion, homeworld: false),
        Planet(planetID: 33, positionX: 57400, positionY: 62600, name: "Spica", team: .orion, homeworld: false),
        Planet(planetID: 34, positionX: 72720, positionY: 70880, name: "Procyon", team: .orion, homeworld: false),
        Planet(planetID: 35, positionX: 61400, positionY: 77000, name: "Polaris", team: .orion, homeworld: false),
        Planet(planetID: 36, positionX: 55600, positionY: 89000, name: "Arcturus", team: .orion, homeworld: false),
        Planet(planetID: 37, positionX: 91000, positionY: 94000, name: "Ursae Majoris", team: .orion, homeworld: false),
        Planet(planetID: 38, positionX: 70000, positionY: 93000, name: "Herculis", team: .orion, homeworld: false),
        Planet(planetID: 39, positionX: 86920, positionY: 68920, name: "Antares", team: .orion, homeworld: false),
        
    ]

    var players: [Player] = []
    
    var activePlayers: [Player] {
        return self.players.filter({$0.status != .free})
    }
    var alivePlayers: [Player] {
        return self.players.filter({$0.status == .alive})
    }
    var humanPlayers: [Player] {
        return self.players.filter({$0.status != .free && $0.context != nil})
    }
    
    var planets: [Planet] = [
        Planet(planetID: 0, positionX: 20000, positionY: 80000, name: "Earth", team: .federation, homeworld: true),
        Planet(planetID: 1, positionX: 10000, positionY: 60000, name: "Rigel", team: .federation, homeworld: false),
        Planet(planetID: 2, positionX: 25000, positionY: 60000, name: "Canopus", team: .federation, homeworld: false),
        Planet(planetID: 3, positionX: 44000, positionY: 81000, name: "Beta Crucis", team: .federation, homeworld: false),
        Planet(planetID: 4, positionX: 39000, positionY: 55000, name: "Organia", team: .federation, homeworld: false),
        Planet(planetID: 5, positionX: 30000, positionY: 90000, name: "Deneb", team: .federation, homeworld: false),
        Planet(planetID: 6, positionX: 45000, positionY: 66000, name: "Ceti Alpha V", team: .federation, homeworld: false),
        Planet(planetID: 7, positionX: 11000, positionY: 75000, name: "Altair", team: .federation, homeworld: false),
        Planet(planetID: 8, positionX: 8000, positionY: 93000, name: "Vega", team: .federation, homeworld: false),
        Planet(planetID: 9, positionX: 32000, positionY: 74000, name: "Alpha Centauri", team: .federation, homeworld: false),
        Planet(planetID: 10, positionX: 20000, positionY: 20000, name: "Rome", team: .roman, homeworld: true),
        Planet(planetID: 11, positionX: 45000, positionY: 7000, name: "Eridani", team: .roman, homeworld: false),
        Planet(planetID: 12, positionX: 4000, positionY: 12000, name: "Aldeberan", team: .roman, homeworld: false),
        Planet(planetID: 13, positionX: 42000, positionY: 44000, name: "Regulus", team: .roman, homeworld: false),
        Planet(planetID: 14, positionX: 13000, positionY: 45000, name: "Capella", team: .roman, homeworld: false),
        Planet(planetID: 15, positionX: 28000, positionY: 8000, name: "Tauri", team: .roman, homeworld: false),
        Planet(planetID: 16, positionX: 28000, positionY: 23000, name: "Draconis", team: .roman, homeworld: false),
        Planet(planetID: 17, positionX: 40000, positionY: 25000, name: "Sirius", team: .roman, homeworld: false),
        Planet(planetID: 18, positionX: 25000, positionY: 44000, name: "Indi", team: .roman, homeworld: false),
        Planet(planetID: 19, positionX: 8000, positionY: 29000, name: "Hydrae", team: .roman, homeworld: false),
        Planet(planetID: 20, positionX: 80000, positionY: 20000, name: "Kazari", team: .kazari, homeworld: true),
        Planet(planetID: 21, positionX: 70000, positionY: 40000, name: "Pliedes V", team: .kazari, homeworld: false),
        Planet(planetID: 22, positionX: 60000, positionY: 10000, name: "Andromeda", team: .kazari, homeworld: false),
        Planet(planetID: 23, positionX: 56400, positionY: 38200, name: "Lalande", team: .kazari, homeworld: false),
        Planet(planetID: 24, positionX: 91120, positionY: 9320, name: "Praxis", team: .kazari, homeworld: false),
        Planet(planetID: 25, positionX: 89960, positionY: 31760, name: "Lyrae", team: .kazari, homeworld: false),
        Planet(planetID: 26, positionX: 70720, positionY: 26320, name: "Scorpii", team: .kazari, homeworld: false),
        Planet(planetID: 27, positionX: 83600, positionY: 45400, name: "Mira", team: .kazari, homeworld: false),
        Planet(planetID: 28, positionX: 54600, positionY: 22600, name: "Cygni", team: .kazari, homeworld: false),
        Planet(planetID: 29, positionX: 73080, positionY: 6640, name: "Achernar", team: .kazari, homeworld: false),
        Planet(planetID: 30, positionX: 80000, positionY: 80000, name: "Orion", team: .orion, homeworld: true),
        Planet(planetID: 31, positionX: 91200, positionY: 56600, name: "Cassiopeia", team: .orion, homeworld: false),
        Planet(planetID: 32, positionX: 70800, positionY: 54200, name: "El Nath", team: .orion, homeworld: false),
        Planet(planetID: 33, positionX: 57400, positionY: 62600, name: "Spica", team: .orion, homeworld: false),
        Planet(planetID: 34, positionX: 72720, positionY: 70880, name: "Procyon", team: .orion, homeworld: false),
        Planet(planetID: 35, positionX: 61400, positionY: 77000, name: "Polaris", team: .orion, homeworld: false),
        Planet(planetID: 36, positionX: 55600, positionY: 89000, name: "Arcturus", team: .orion, homeworld: false),
        Planet(planetID: 37, positionX: 91000, positionY: 94000, name: "Ursae Majoris", team: .orion, homeworld: false),
        Planet(planetID: 38, positionX: 70000, positionY: 93000, name: "Herculis", team: .orion, homeworld: false),
        Planet(planetID: 39, positionX: 86920, positionY: 68920, name: "Antares", team: .orion, homeworld: false),
        
    ]
    //var queue: [Player] = []
    static let MAXPLAYERS = 32
    var homeworld: [Team:Planet] = [:]
    
    //var team1 = Team.federation
    //var team2 = Team.roman
    
    //var users: [User] = []
    var userDatabase = UserDatabase()
    
    var robotController = RobotController()
        
    var gameState: GameState = .intramural
    let tModeThreshold = 6
        
    var metaserver: MetaserverUDP? = nil

    //https://stackoverflow.com/questions/8304702/how-do-i-create-a-nstimer-on-a-background-thread
    /*func scheduleTimerInBackgroundThread(){
        DispatchQueue.global().async(execute: {
            //This method schedules timer to current runloop.
            self.weakTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
            self.weakTimer?.tolerance = 0.03
            //start runloop manually, otherwise timer won't fire
            //add timer before run, otherwise runloop find there's nothing to do and exit directly.
            RunLoop.current.run()
        })
    }*/
    
    init() {
        //logger.info("Universe.init")
        
        //planets = Universe.startPlanets
        for slotnum in 0 ..< Universe.MAXPLAYERS {
            let homeworld: Planet?
            let planetShuffle = planets.shuffled()
            let player: Player
            switch netrekOptions.gameStyle {
                
            case .bronco:
                player = Player(slot: slotnum, universe: self)
            case .empire:
                homeworld = planetShuffle[slotnum]
                player = Player(slot: slotnum, universe: self, homeworld: homeworld)
            }
            self.players.append(player)
        }

        homeworld[.federation] = planets.first(where: {$0.name == "Earth"})!
        homeworld[.roman] = planets.first(where: {$0.name == "Rome"})!
        homeworld[.kazari] = planets.first(where: {$0.name == "Kazari"})!
        homeworld[.orion] = planets.first(where: {$0.name == "Orion"})!
        
        //timer = Timer.scheduledTimer(timeInterval: 1.0 / updatesPerSecond, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)

        //timer = Timer(timeInterval: 1.0 / updatesPerSecond, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / updatesPerSecond, repeats: true) {_ in
            self.timerFired()
        }
        timer?.tolerance = 0.3 / updatesPerSecond
        logger.info("Timer initialized")
        if let timer = timer {
            RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
        }
        if netrekOptions.domainName != nil {
            self.metaserver = MetaserverUDP(universe: self)
            //we send to metaserver later in timer
            /*if let metaserver = self.metaserver {
                metaserver.sendReport(ip: "161.35.226.186", port: 3521)
            } else {
                //cannot log here
                print("Error: unable to send to metaserver")
            }*/
        } else {
            //cannot log here
            print("No metaserver specified on CLI: skipping metaserver reports")
        }
        logger.info("scheduling timer")
    }
    
    deinit {
        logger.critical("universe.deinit")
    }
    /*
     SP_PLANET_LOC pnum= 1 x= 10000 y= 60000 name= Rigel
     SP_PLANET_LOC pnum= 2 x= 25000 y= 60000 name= Canopus
     SP_PLANET_LOC pnum= 3 x= 44000 y= 81000 name= Beta Crucis
     SP_PLANET_LOC pnum= 4 x= 39000 y= 55000 name= Organia
     SP_PLANET_LOC pnum= 5 x= 30000 y= 90000 name= Deneb
     SP_PLANET_LOC pnum= 6 x= 45000 y= 66000 name= Ceti Alpha V
     SP_PLANET_LOC pnum= 7 x= 11000 y= 75000 name= Altair
     SP_PLANET_LOC pnum= 8 x= 8000 y= 93000 name= Vega
     SP_PLANET_LOC pnum= 9 x= 32000 y= 74000 name= Alpha Centauri
     SP_PLANET_LOC pnum= 10 x= 20000 y= 20000 name= Romulus
     SP_PLANET_LOC pnum= 11 x= 45000 y= 7000 name= Eridani
     SP_PLANET_LOC pnum= 12 x= 4000 y= 12000 name= Aldeberan
     SP_PLANET_LOC pnum= 13 x= 42000 y= 44000 name= Regulus
     SP_PLANET_LOC pnum= 14 x= 13000 y= 45000 name= Capella
     SP_PLANET_LOC pnum= 15 x= 28000 y= 8000 name= Tauri
     SP_PLANET_LOC pnum= 16 x= 28000 y= 23000 name= Draconis
     SP_PLANET_LOC pnum= 17 x= 40000 y= 25000 name= Sirius
     SP_PLANET_LOC pnum= 18 x= 25000 y= 44000 name= Indi
     SP_PLANET_LOC pnum= 19 x= 8000 y= 29000 name= Hydrae
     SP_PLANET_LOC pnum= 20 x= 80000 y= 80000 name= Klingus
     SP_PLANET_LOC pnum= 21 x= 70000 y= 40000 name= Pliedes V
     SP_PLANET_LOC pnum= 22 x= 60000 y= 10000 name= Andromeda
     SP_PLANET_LOC pnum= 23 x= 56400 y= 38200 name= Lalande
     SP_PLANET_LOC pnum= 24 x= 91120 y= 9320 name= Praxis
     SP_PLANET_LOC pnum= 25 x= 89960 y= 31760 name= Lyrae
     SP_PLANET_LOC pnum= 26 x= 70720 y= 26320 name= Scorpii
     SP_PLANET_LOC pnum= 27 x= 83600 y= 45400 name= Mira
     SP_PLANET_LOC pnum= 28 x= 54600 y= 22600 name= Cygni
     SP_PLANET_LOC pnum= 29 x= 73080 y= 6640 name= Achernar
     SP_PLANET_LOC pnum= 30 x= 80000 y= 80000 name= Orion
     SP_PLANET_LOC pnum= 31 x= 91200 y= 56600 name= Cassiopeia
     SP_PLANET_LOC pnum= 32 x= 70800 y= 54200 name= El Nath
     SP_PLANET_LOC pnum= 33 x= 57400 y= 62600 name= Spica
     SP_PLANET_LOC pnum= 34 x= 72720 y= 70880 name= Procyon
     SP_PLANET_LOC pnum= 35 x= 61400 y= 77000 name= Polaris
     SP_PLANET_LOC pnum= 36 x= 55600 y= 89000 name= Arcturus
     SP_PLANET_LOC pnum= 37 x= 91000 y= 94000 name= Ursae Majoris
     SP_PLANET_LOC pnum= 38 x= 70000 y= 93000 name= Herculis
     SP_PLANET_LOC pnum= 39 x= 86920 y= 68920 name= Antares
     */
    
    public func shutdownWarning() {
        print("sending shutdown warnings")
        logger.info("Sending shutdown warnings")
        for player in self.activePlayers {
            player.sendMessage(message: "Alert: Netrek Server shutting down.  Try again in a few minutes.")
        }
    }
    public func shutdownComplete() {
        print("shutdown complete")
        exit(0)
    }
    func randomFreeSlot() -> Int? {
        let freeSlots = self.players.filter({$0.status == .free})
        guard let randomFreeSlot = freeSlots.randomElement() else {
            return nil
        }
        return randomFreeSlot.slot
        /*for (slotnum,player) in self.players.enumerated() {
            if player.status == .free {
                return slotnum
            }
        }
        return nil*/
    }
    func sendPlanetUpdates(_ forceUpdate: Bool = false) {
        // this is called every 0.1 seconds
        // it only sends updates for planets with needsUpdate set
        // but always sends updates if force = true
        for planet in planets.filter({($0.needsUpdate == true) || forceUpdate}) {
            logger.debug("Sending SP_PLANETs for \(planet.name)")
            let data = MakePacket.spPlanet(planet: planet)
            for player in activePlayers {
                if let context = player.context {
                    context.eventLoop.execute {
                        let buffer = context.channel.allocator.buffer(bytes: data)
                        _ = context.channel.write(buffer)
                    }
                }
            }
            planet.needsUpdate = false
        }
    }
    @objc func timerFired() {
        self.timerCount += 1
        //logger.trace("\(#file) \(#function) count \(self.timerCount)")
        self.sendPlanetUpdates()
        for player in self.players {
            if player.status != .free {
                player.shortTimerFired()
            }
        }
        
        //pop a planet every half second if we have at least one player
        if timerCount % (Int(updatesPerSecond) / 2) == 0 && players.filter({ $0.status != .free}).count > 0 {
            if let planet = planets.randomElement() {
                planet.pop()
            }
        }
        //once per second actions
        if timerCount % Int(self.updatesPerSecond) == 0 {
            for player in self.players {
                if player.status != .free {
                    player.secondTimerFired()
                }
            }
            robotController.secondTimerFired()
        }
        //once per minute actions
        if timerCount % 60 * Int(self.updatesPerSecond) == 0 {
            for player in self.players {
                if player.status != .free {
                    player.minuteTimerFired()
                }
            }
        }
        //send a packet every tick
        for player in self.humanPlayers {
            player.flush()
        }
        //metaserver update every 4 minutes
        if timerCount % 240 * Int(self.updatesPerSecond) == 0 {
            if let metaserver = self.metaserver {
                metaserver.sendReport(ip: "69.164.215.96", port: 3521)
                metaserver.sendReport(ip: "63.170.91.110", port: 3521)
            } else {
                logger.error("Error: unable to send to metaserver")
            }
        }
        // stats report once per 30 minutes
        //TODO  change to 30 minutes
        if timerCount % (60 * Int(self.updatesPerSecond)) == 0 {
            userDatabase.updateStats()
            for player in humanPlayers {
                player.statsReport()
            }
            // save user database after stats report
            try? userDatabase.save()
        }
    }
    public func checkForWin() {
        switch netrekOptions.gameStyle {
            
        case .bronco:
            checkForWinBronco()
        case .empire:
            checkForWinEmpire()
        }
    }
    func checkForWinEmpire() {
        var planetCount: [Team:Int] = [:]
        for team in Team.allCases {
            planetCount[team] = 0
        }
        for planet in self.planets {
            planetCount[planet.team]! += 1
        }
        let goal = self.planets.count * 3 / 4
        for team in Team.empireTeams {
            if planetCount[team]! >= goal {
                empireWin(winner: team)
            }
        }
    }
    func checkForWinBronco() {
        var planetCount: [Team:Int] = [:]
        for team in Team.allCases {
            planetCount[team] = 0
        }
        for planet in self.planets {
            planetCount[planet.team]! += 1
        }
        for team in Team.broncoTeams {
            if planetCount[team]! < 1 {
                broncoLoss(loser: team)
            }
        }
    }
    func broncoLoss(loser: Team) {
        let winner = Team.broncoTeams.filter({$0 != loser}).first!
        for player in humanPlayers {
            player.sendMessage(message: "\(winner) dominates the galaxy!")
        }
        for player in activePlayers.filter({$0.team == loser}) {
            player.impact(damage: 9999, whyDead: .genocide)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.broncoReset()
        }
    }
    
    func empireWin(winner: Team) {
        for player in humanPlayers {
            player.sendMessage(message: "\(winner) dominates the galaxy!")
        }
        for player in activePlayers.filter({$0.team != winner}) {
            player.impact(damage: 9999, whyDead: .genocide)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.empireReset()
        }
    }
    
    func empireReset() {
        self.planets = [
            Planet(planetID: 0, positionX: 20000, positionY: 80000, name: "Earth", team: .federation, homeworld: true),
            Planet(planetID: 1, positionX: 10000, positionY: 60000, name: "Rigel", team: .federation, homeworld: false),
            Planet(planetID: 2, positionX: 25000, positionY: 60000, name: "Canopus", team: .federation, homeworld: false),
            Planet(planetID: 3, positionX: 44000, positionY: 81000, name: "Beta Crucis", team: .federation, homeworld: false),
            Planet(planetID: 4, positionX: 39000, positionY: 55000, name: "Organia", team: .federation, homeworld: false),
            Planet(planetID: 5, positionX: 30000, positionY: 90000, name: "Deneb", team: .federation, homeworld: false),
            Planet(planetID: 6, positionX: 45000, positionY: 66000, name: "Ceti Alpha V", team: .federation, homeworld: false),
            Planet(planetID: 7, positionX: 11000, positionY: 75000, name: "Altair", team: .federation, homeworld: false),
            Planet(planetID: 8, positionX: 8000, positionY: 93000, name: "Vega", team: .federation, homeworld: false),
            Planet(planetID: 9, positionX: 32000, positionY: 74000, name: "Alpha Centauri", team: .federation, homeworld: false),
            Planet(planetID: 10, positionX: 20000, positionY: 20000, name: "Rome", team: .roman, homeworld: true),
            Planet(planetID: 11, positionX: 45000, positionY: 7000, name: "Eridani", team: .roman, homeworld: false),
            Planet(planetID: 12, positionX: 4000, positionY: 12000, name: "Aldeberan", team: .roman, homeworld: false),
            Planet(planetID: 13, positionX: 42000, positionY: 44000, name: "Regulus", team: .roman, homeworld: false),
            Planet(planetID: 14, positionX: 13000, positionY: 45000, name: "Capella", team: .roman, homeworld: false),
            Planet(planetID: 15, positionX: 28000, positionY: 8000, name: "Tauri", team: .roman, homeworld: false),
            Planet(planetID: 16, positionX: 28000, positionY: 23000, name: "Draconis", team: .roman, homeworld: false),
            Planet(planetID: 17, positionX: 40000, positionY: 25000, name: "Sirius", team: .roman, homeworld: false),
            Planet(planetID: 18, positionX: 25000, positionY: 44000, name: "Indi", team: .roman, homeworld: false),
            Planet(planetID: 19, positionX: 8000, positionY: 29000, name: "Hydrae", team: .roman, homeworld: false),
            Planet(planetID: 20, positionX: 80000, positionY: 20000, name: "Kazari", team: .kazari, homeworld: true),
            Planet(planetID: 21, positionX: 70000, positionY: 40000, name: "Pliedes V", team: .kazari, homeworld: false),
            Planet(planetID: 22, positionX: 60000, positionY: 10000, name: "Andromeda", team: .kazari, homeworld: false),
            Planet(planetID: 23, positionX: 56400, positionY: 38200, name: "Lalande", team: .kazari, homeworld: false),
            Planet(planetID: 24, positionX: 91120, positionY: 9320, name: "Praxis", team: .kazari, homeworld: false),
            Planet(planetID: 25, positionX: 89960, positionY: 31760, name: "Lyrae", team: .kazari, homeworld: false),
            Planet(planetID: 26, positionX: 70720, positionY: 26320, name: "Scorpii", team: .kazari, homeworld: false),
            Planet(planetID: 27, positionX: 83600, positionY: 45400, name: "Mira", team: .kazari, homeworld: false),
            Planet(planetID: 28, positionX: 54600, positionY: 22600, name: "Cygni", team: .kazari, homeworld: false),
            Planet(planetID: 29, positionX: 73080, positionY: 6640, name: "Achernar", team: .kazari, homeworld: false),
            Planet(planetID: 30, positionX: 80000, positionY: 80000, name: "Orion", team: .orion, homeworld: true),
            Planet(planetID: 31, positionX: 91200, positionY: 56600, name: "Cassiopeia", team: .orion, homeworld: false),
            Planet(planetID: 32, positionX: 70800, positionY: 54200, name: "El Nath", team: .orion, homeworld: false),
            Planet(planetID: 33, positionX: 57400, positionY: 62600, name: "Spica", team: .orion, homeworld: false),
            Planet(planetID: 34, positionX: 72720, positionY: 70880, name: "Procyon", team: .orion, homeworld: false),
            Planet(planetID: 35, positionX: 61400, positionY: 77000, name: "Polaris", team: .orion, homeworld: false),
            Planet(planetID: 36, positionX: 55600, positionY: 89000, name: "Arcturus", team: .orion, homeworld: false),
            Planet(planetID: 37, positionX: 91000, positionY: 94000, name: "Ursae Majoris", team: .orion, homeworld: false),
            Planet(planetID: 38, positionX: 70000, positionY: 93000, name: "Herculis", team: .orion, homeworld: false),
            Planet(planetID: 39, positionX: 86920, positionY: 68920, name: "Antares", team: .orion, homeworld: false),
            
        ]
        for player in players {
            player.homeworld = player.getRandomHomeworld()
        }
        for player in activePlayers {
            player.impact(damage: 9999, whyDead: .genocide)
        }
        for player in humanPlayers {
            player.sendMessage(message: "A new war spreads across the new galaxy!")
            player.sendInitialTransfer()
        }
    }
    
    func broncoReset() {
        self.planets = [
            Planet(planetID: 0, positionX: 20000, positionY: 80000, name: "Earth", team: .federation, homeworld: true),
            Planet(planetID: 1, positionX: 10000, positionY: 60000, name: "Rigel", team: .federation, homeworld: false),
            Planet(planetID: 2, positionX: 25000, positionY: 60000, name: "Canopus", team: .federation, homeworld: false),
            Planet(planetID: 3, positionX: 44000, positionY: 81000, name: "Beta Crucis", team: .federation, homeworld: false),
            Planet(planetID: 4, positionX: 39000, positionY: 55000, name: "Organia", team: .federation, homeworld: false),
            Planet(planetID: 5, positionX: 30000, positionY: 90000, name: "Deneb", team: .federation, homeworld: false),
            Planet(planetID: 6, positionX: 45000, positionY: 66000, name: "Ceti Alpha V", team: .federation, homeworld: false),
            Planet(planetID: 7, positionX: 11000, positionY: 75000, name: "Altair", team: .federation, homeworld: false),
            Planet(planetID: 8, positionX: 8000, positionY: 93000, name: "Vega", team: .federation, homeworld: false),
            Planet(planetID: 9, positionX: 32000, positionY: 74000, name: "Alpha Centauri", team: .federation, homeworld: false),
            Planet(planetID: 10, positionX: 20000, positionY: 20000, name: "Rome", team: .roman, homeworld: true),
            Planet(planetID: 11, positionX: 45000, positionY: 7000, name: "Eridani", team: .roman, homeworld: false),
            Planet(planetID: 12, positionX: 4000, positionY: 12000, name: "Aldeberan", team: .roman, homeworld: false),
            Planet(planetID: 13, positionX: 42000, positionY: 44000, name: "Regulus", team: .roman, homeworld: false),
            Planet(planetID: 14, positionX: 13000, positionY: 45000, name: "Capella", team: .roman, homeworld: false),
            Planet(planetID: 15, positionX: 28000, positionY: 8000, name: "Tauri", team: .roman, homeworld: false),
            Planet(planetID: 16, positionX: 28000, positionY: 23000, name: "Draconis", team: .roman, homeworld: false),
            Planet(planetID: 17, positionX: 40000, positionY: 25000, name: "Sirius", team: .roman, homeworld: false),
            Planet(planetID: 18, positionX: 25000, positionY: 44000, name: "Indi", team: .roman, homeworld: false),
            Planet(planetID: 19, positionX: 8000, positionY: 29000, name: "Hydrae", team: .roman, homeworld: false),
            Planet(planetID: 20, positionX: 80000, positionY: 20000, name: "Kazari", team: .kazari, homeworld: true),
            Planet(planetID: 21, positionX: 70000, positionY: 40000, name: "Pliedes V", team: .kazari, homeworld: false),
            Planet(planetID: 22, positionX: 60000, positionY: 10000, name: "Andromeda", team: .kazari, homeworld: false),
            Planet(planetID: 23, positionX: 56400, positionY: 38200, name: "Lalande", team: .kazari, homeworld: false),
            Planet(planetID: 24, positionX: 91120, positionY: 9320, name: "Praxis", team: .kazari, homeworld: false),
            Planet(planetID: 25, positionX: 89960, positionY: 31760, name: "Lyrae", team: .kazari, homeworld: false),
            Planet(planetID: 26, positionX: 70720, positionY: 26320, name: "Scorpii", team: .kazari, homeworld: false),
            Planet(planetID: 27, positionX: 83600, positionY: 45400, name: "Mira", team: .kazari, homeworld: false),
            Planet(planetID: 28, positionX: 54600, positionY: 22600, name: "Cygni", team: .kazari, homeworld: false),
            Planet(planetID: 29, positionX: 73080, positionY: 6640, name: "Achernar", team: .kazari, homeworld: false),
            Planet(planetID: 30, positionX: 80000, positionY: 80000, name: "Orion", team: .orion, homeworld: true),
            Planet(planetID: 31, positionX: 91200, positionY: 56600, name: "Cassiopeia", team: .orion, homeworld: false),
            Planet(planetID: 32, positionX: 70800, positionY: 54200, name: "El Nath", team: .orion, homeworld: false),
            Planet(planetID: 33, positionX: 57400, positionY: 62600, name: "Spica", team: .orion, homeworld: false),
            Planet(planetID: 34, positionX: 72720, positionY: 70880, name: "Procyon", team: .orion, homeworld: false),
            Planet(planetID: 35, positionX: 61400, positionY: 77000, name: "Polaris", team: .orion, homeworld: false),
            Planet(planetID: 36, positionX: 55600, positionY: 89000, name: "Arcturus", team: .orion, homeworld: false),
            Planet(planetID: 37, positionX: 91000, positionY: 94000, name: "Ursae Majoris", team: .orion, homeworld: false),
            Planet(planetID: 38, positionX: 70000, positionY: 93000, name: "Herculis", team: .orion, homeworld: false),
            Planet(planetID: 39, positionX: 86920, positionY: 68920, name: "Antares", team: .orion, homeworld: false),
            
        ]
        for player in activePlayers {
            player.impact(damage: 9999, whyDead: .genocide)
        }
        for player in humanPlayers {
            player.sendMessage(message: "A new war spreads across the new galaxy!")
        }
    }
    
    func player(context: ChannelHandlerContext) -> Player? {
        for player in self.players {
            if context === player.context {
                return player
            }
        }
        logger.error("Error: \(#file) \(#function) unable to find player for context \(context)")
        return nil
    }
    func player(remoteAddress: SocketAddress) -> Player? {
        return self.players.first(where: {$0.remoteAddress == remoteAddress })
    }
    /*func player(connection: NWConnection) -> Player? {
        for (slot, player) in self.players.enumerated() {
            if connection === player.connection?.connection {
                return player
            }
        }
        logger.error("Error: \(#file) \(#function) unable to find player for connection \(connection)")
        return nil
    }*/
    /*func connectionEnded(connection: ServerConnection) {
        for (slot,player) in self.players.enumerated() {
            if player.connection === connection {
                player.disconnected()
            }
        }
    }*/
    /*func addPlayer(connection: ServerConnection) {
        if let freeSlot = firstFreeSlot() {
            self.players[freeSlot].connected(connection: connection)
        }
    }*/
    func addPlayer(context: ChannelHandlerContext) {
        //if let freeSlot = randomFreeSlot() {
        if let player = self.players.first(where: {$0.status == .free}) {
            player.connected(context: context)
        }
        self.setGameMode()
    }
    
    public func setGameMode() {
        if self.humanPlayers.count >= tModeThreshold {
            self.gameState = .tmode
        } else {
            self.gameState = .intramural
        }

    }
    
    /*func send(playerid: Int, data: Data) {
        guard let player = players[safe: playerid] else {
            logger.error("Error \(#file) \(#function) no connection for id \(playerid) ")
            return
        }
        logger.trace("sending \(data.count) bytes to playerid \(playerid)")
        player.connection?.send(data: data)
    }*/
}
