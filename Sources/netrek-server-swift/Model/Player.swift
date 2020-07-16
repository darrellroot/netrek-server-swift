//
//  Player.swift
//  NetrekServer
//
//  Created by Darrell Root on 6/19/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
// 

import Foundation
import NIO

class Player: Thing {
    static let orbitRadius = 800.0
    static let orbitRange = 900.0 // for entering orbit
    static let detDist = 1700.0 // for detonating enemy torp
    static let planetRange = 1500.0 //range at which planet can attack player
    static let tractorCost = 20
    static let tractorHeat = 5
    var slot: Int
    //var state: PlayerState
    let universe: Universe
    //var connection: ServerConnection?
    var context: ChannelHandlerContext?
    var remoteAddress: SocketAddress? = nil

    var user: User? = nil
    var robot: Robot? = nil
    var team: Team
    var armies = 0
    var maxArmies: Int {
        //return min(4,self.ship.maxArmies)
        //TODO after testing activate kill army limit
        switch self.ship {
        case .assault:
            return min(Int(3.0 * kills), self.ship.maxArmies)
        default:
            return min(Int(2.0 * kills), self.ship.maxArmies)
        }
    }
    var plasmaEquipped = false
    
    var tractor: Player? = nil // player number of tractor target
    var tractorMode = TractorMode.off
    var refitting = false //important to reset back to false
        
    var damage = 0.0
    var shield = 100.0
    var fuel = 10000 {
        didSet {
            if fuel > self.ship.maxFuel {
                self.fuel = self.ship.maxFuel
            }
            if fuel < 0 {
                fuel = 0
            }
        }
    }
    var etmp = 0 {
        didSet {
            if etmp >= 1000 {
                self.enginesOverheated = true
            }
            if etmp <= 0 {
                self.enginesOverheated = false
                self.etmp = 0
            }
        }
    }
    var wtmp = 0 {
        didSet {
            if wtmp >= 1000 {
                self.weaponsOverheated = true
            }
            if wtmp <= 0 {
                self.weaponsOverheated = false
                self.wtmp = 0
            }
        }
    }
    var whydead: WhyDead = .none
    var whodead = 0
    
    var torpedoes: [Torpedo] = []
    var plasma: Plasma! = nil
    var lastTorpedoFired = Date()
    var lastLaserFired = Date()
    
    private(set) var shieldsUp = false {
        didSet {
            if self.shieldsUp == true {
                self.repair = false
                self.transporter = .off
            }
        }
    }
    var repair = false
    var bomb = false
    var weaponsOverheated = false {
        didSet {
            if weaponsOverheated && !oldValue {
                self.sendMessage(message: "Weapons overheated!")
            }
        }
    }
    var enginesOverheated = false {
        didSet {
            if enginesOverheated && !oldValue {
                self.helmSpeed = 1
                self.sendMessage(message: "Engines overheated!")
            }
        }
    }
    var orbit: Planet? = nil {
        didSet {
            if let orbit = self.orbit {
                orbit.seen[self.team] = true
            } else {
                self.bomb = false
            }
        }
    }
    var orbitRadian = 0.0 {
        didSet {
            if orbitRadian < 0.0 {
                orbitRadian += Double.pi * 2
            }
            if orbitRadian >= Double.pi * 2 {
                orbitRadian -= Double.pi * 2
            }
        }
    }
    var cloak = false
    var transporter = Transporter.off {
        didSet {
            if transporter != .off {
                self.shieldsUp = false
            }
        }
    }
    var selfDestruct = false
    var alertCondition = AlertCondition.green
    var playerLock: Player? = nil
    var planetLock: Planet? = nil
    
    var ship: ShipType = .cruiser
    var kills: Double = 0.0 {
        didSet {
            if let user = self.user {
                switch self.ship {
                case .starbase:
                    if self.kills > user.sbMaxKills {
                        user.sbMaxKills = self.kills
                    }
                default:
                    if self.kills > user.maxKills {
                        user.maxKills = self.kills
                    }
                }
            }
        }
    }
    var status: SlotStatus = .free
    
    var positionX: Double = -10000
    var positionY: Double = -10000 // reminder Y=0 is top of the map, Y = 10000 is bottom of map
    
    var laser: Laser
    
    var direction: Double = 0.0 { // radians
        didSet {
            if direction < 0.0 {
                direction += Double.pi * 2
            }
            if direction >= Double.pi * 2 {
                direction -= Double.pi * 2
            }
        }
    }
    
    var directionNetrek: Int {
        // 0 - 255
        // inclusive, 0 is straight up, 64 straight right
        let value = Int(64.0 - 128.0 * self.direction / Double.pi)
        if value < 0 {
            return value + 256
        } else {
            return value
        }
    }
    var helmDirection: Double = 0.0 { // radians
        didSet {
            if helmDirection < 0 {
                helmDirection += Double.pi * 2
            }
            if helmDirection >= Double.pi * 2 {
                helmDirection -= Double.pi * 2
            }
        }
    }
    
    var speed: Double = 0.0
    var helmSpeed: Double = 0.0 {
        didSet {
            if self.helmSpeed > 0 {
                self.repair = false
            }
        }
    }
    var maxSpeed: Double {
        return max(0, round((self.ship.maxSpeed * (1 - self.damage / self.ship.maxDamage)+0.49)))
    }
    
    var flags: UInt32 {
        var flags: UInt32 = 0
        if self.shieldsUp {
            flags += PlayerStatus.shield.rawValue
        }
        if self.repair {
            flags += PlayerStatus.repair.rawValue
        }
        if self.bomb {
            flags += PlayerStatus.bomb.rawValue
        }
        if self.orbit != nil {
            flags += PlayerStatus.orbit.rawValue
        }
        if self.cloak {
            flags += PlayerStatus.cloak.rawValue
        }
        if self.weaponsOverheated {
            flags += PlayerStatus.weaponTemp.rawValue
        }
        if self.enginesOverheated {
            flags += PlayerStatus.engineTemp.rawValue
        }
        switch self.transporter {
        case .beamup:
            flags += PlayerStatus.beamup.rawValue
        case .beamdown:
            flags += PlayerStatus.beamdown.rawValue
        case .off:
            break
        }
        if self.selfDestruct {
            flags += PlayerStatus.selfDestruct.rawValue
        }
        switch self.alertCondition {
        case .green:
            flags += PlayerStatus.greenAlert.rawValue
        case .yellow:
            flags += PlayerStatus.yellowAlert.rawValue
        case .red:
            flags += PlayerStatus.redAlert.rawValue
        }
        if self.playerLock != nil {
            flags += PlayerStatus.playerLock.rawValue
        }
        if self.planetLock != nil {
            flags += PlayerStatus.planetLock.rawValue
        }
        switch self.tractorMode {
        case .tractor:
            flags += PlayerStatus.tractor.rawValue
        case .pressor:
            flags += PlayerStatus.pressor.rawValue
        case .off:
            break
        }
        
        
        return flags

    }
    
    init(slot: Int, universe: Universe) {
        self.slot = slot
        self.status = .free
        self.universe = universe
        self.team = .independent
        self.laser = Laser(universe: universe)

        for count in 0 ..< 8 {
            self.torpedoes.append(Torpedo(universe: self.universe, player: self, number: self.slot * 8 + count))
        }
        self.laser.player = self
        self.plasma = Plasma(universe: self.universe, player: self, number: self.slot)
    }
    
    public func explode(attacker: Player? = nil, planet: Planet? = nil) {
        for player in universe.players.filter({$0.status == .alive}) {
            guard player !== self else {
                continue
            }
            let distance = sqrt((player.positionX - self.positionX) * (player.positionX - self.positionX) + (player.positionY - self.positionY) * (player.positionY - self.positionY))
            guard distance <= self.ship.explosionRange else {
                continue
            }
            let damage = self.ship.explosionDamage * (1 - distance / self.ship.explosionRange)
            player.impact(damage: damage, attacker: attacker, planet: planet, whyDead: .explosion)
        }
        /*DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if self.status == .explode {
                self.status = .dead
            }
        }*/
    }
    public func impact(damage: Double, attacker: Player? = nil, planet: Planet? = nil, whyDead: WhyDead) {
        // attacker is either player or planet but not both
        guard damage >= 0 else {
            debugPrint("\(#file) \(#function) error: damage \(damage)")
            return
        }
        var remainingDamage = damage
        if shieldsUp {
            if shield >= remainingDamage {
                shield -= remainingDamage
                return
            } else {
                remainingDamage -= shield
                shield = 0
            }
        }
        self.damage += remainingDamage
        if self.damage >= self.ship.maxDamage {
            self.status = .explode
            self.whydead = whyDead
            self.whodead = attacker?.slot ?? 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.explode(attacker: attacker, planet: planet)
            }
            if let attacker = attacker {
                attacker.kills = attacker.kills + 1.0 + self.kills / 10.0 + Double(self.armies) / 10.0
                let victimLabel: String
                if let user = self.user {
                    victimLabel = self.team.letter + self.slot.hex + " " + user.name
                } else {
                    victimLabel = self.team.letter + self.slot.hex
                }
                let attackLabel: String
                if let attackUser = attacker.user {
                    attackLabel = attacker.team.letter + attacker.slot.hex + " " +  attackUser.name
                } else {
                    attackLabel = attacker.team.letter + attacker.slot.hex
                }
                for player in universe.players {
                    player.sendMessage(message: "\(victimLabel) was kill \(attacker.kills) for \(attackLabel)")
                }
            }
            if let planet = planet {
                let victimLabel: String
                if let user = self.user {
                    victimLabel = self.team.letter + self.slot.hex + " " + user.name
                } else {
                    victimLabel = self.team.letter + self.slot.hex
                }
                for player in universe.players {
                    player.sendMessage(message: "\(victimLabel) was kill for \(planet.name)")
                }
            }
            if let victor = attacker?.user {
                switch universe.gameState {
                    
                case .intramural:
                    victor.overallKills += 1
                    victor.intramuralArmies += 1
                case .tmode:
                    victor.tKills += 1
                    victor.overallKills +=  1
                    victor.tArmies += self.armies
                }
                if self.ship == .starbase {
                    victor.sbKills += 1
                }
            }
            if let loser = self.user {
                switch universe.gameState {
                    
                case .intramural:
                    loser.overallLosses += 1
                    
                case .tmode:
                    loser.tLosses += 1
                    loser.overallLosses += 1
                }
                if self.ship == .starbase {
                    loser.sbLosses += 1
                }
            }
            
            let spPStatus = MakePacket.spPStatus(player: self)
            for player in self.universe.players.filter({$0.status == .alive || $0.status == .explode }) {
                if let context = player.context {
                    context.eventLoop.execute {
                        let buffer = context.channel.allocator.buffer(bytes: spPStatus)
                        _ = context.channel.writeAndFlush(buffer)
                    }
                }
                //player.connection?.send(data: spPStatus)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.status = .dead
                let spPStatus = MakePacket.spPStatus(player: self)
                for player in self.universe.players.filter({$0.status == .alive || $0.status == .explode }) {
                    if let context = player.context {
                        context.eventLoop.execute {
                            let buffer = context.channel.allocator.buffer(bytes: spPStatus)
                            _ = context.channel.writeAndFlush(buffer)
                        }
                    }

                    //player.connection?.send(data: spPStatus)
                }
            }
        }
    }
    func disconnected() {
        debugPrint("player \(slot) disconnected")
        for player in universe.activePlayers {
            player.sendMessage(message: "Player \(self.team.letter)\(self.slot.hex) \(self.user?.name ?? "unknown") disconnected")
        }
        self.reset()
    }
    func newShip(ship: ShipType) {
        // warning: could be called from reset()
        self.ship = ship
        self.fuel = self.ship.maxFuel
        self.status = .alive
        self.damage = 0
        self.shield = ship.maxShield
        self.armies = 0
        self.tractor = nil
        self.fuel = ship.maxFuel
        self.refitting = false
        self.etmp = 0
        self.wtmp = 0
        if self.ship == .starbase {
            self.plasmaEquipped = true
        } else {
            self.plasmaEquipped = false
        }
        //self.whydead
        self.whodead = 0
        self.whydead = .none
        self.shieldsUp = false
        self.repair = false
        self.bomb = false
        self.weaponsOverheated = false
        self.enginesOverheated = false
        self.tractorMode = .off
        self.orbit = nil
        self.cloak = false
        self.transporter = .off
        self.selfDestruct = false
        self.alertCondition = .green
        self.playerLock = nil
        self.planetLock = nil
        self.kills = 0
        self.direction = 0
        self.helmDirection = 0
        self.speed = 0
        self.helmSpeed = 0
    }
    func reset() {
        debugPrint("player \(slot) resetting")
        self.context = nil
        self.remoteAddress = nil
        //self.connection = nil
        self.user = nil
        self.robot = nil
        self.team = .independent
        self.refitting = false
        newShip(ship: .cruiser)
        self.status = .free
        let spPStatus = MakePacket.spPStatus(player: self)

        for torpedo in self.torpedoes {
            torpedo.reset()
        }
        for player in universe.players.filter ({ $0.status != .free}) {
            if let context = player.context {
                context.eventLoop.execute {
                    let buffer = context.channel.allocator.buffer(bytes: spPStatus)
                    _ = context.channel.writeAndFlush(buffer)
                }
            }
            //player.connection?.send(data: spPStatus)

        }
    }
    func enterOrbit() {
        guard self.speed <= 2.5 else {
            let spMessage = MakePacket.spMessage(message: "Helmsman: Captain, the maximum safe speed for docking or orbiting is warp 2!", from: 255)
            if let context = context {
                context.eventLoop.execute {
                    let buffer = context.channel.allocator.buffer(bytes: spMessage)
                    _ = context.channel.writeAndFlush(buffer)
                }

            }
            return
        }
        self.orbit = nil
        for planet in universe.planets {
            if sqrt((planet.positionX - self.positionX) * (planet.positionX - self.positionX) + (planet.positionY - self.positionY) * (planet.positionY - self.positionY)) <= Player.orbitRange {
                self.orbit = planet
                break
            }
        }
        guard let orbit = self.orbit else {
            let spMessage = MakePacket.spMessage(message: "Captain: We are not in orbit range of a planet", from: 255)
            if let context = context {
                context.eventLoop.execute {
                    let buffer = context.channel.allocator.buffer(bytes: spMessage)
                    _ = context.channel.writeAndFlush(buffer)
                }
            }

            //self.connection?.send(data: spMessage)
            return
        }
        
        self.orbitRadian = atan2(-1 * self.positionY - orbit.positionY, self.positionX - orbit.positionX)
        let spMessage = MakePacket.spMessage(message: "Entering standard orbit of \(orbit.name)", from: 255)
        if let context = context {
            context.eventLoop.execute {
                let buffer = context.channel.allocator.buffer(bytes: spMessage)
                _ = context.channel.writeAndFlush(buffer)
            }
        }

        //self.connection?.send(data: spMessage)
        self.speed = 1
        self.helmSpeed = 1
        self.planetLock = nil
        self.playerLock = nil
    }
    func fireLaser(direction: UInt8) {
        guard self.weaponsOverheated == false else {
            self.sendMessage(message: "Weapons overheated!")
            return
        }
        guard self.cloak == false else {
            self.sendMessage(message: "Cannot fire while cloaked")
            return
        }
        guard self.fuel >= Int(self.ship.laserCost) else {
            self.sendMessage(message: "You do not have enough fuel to fire a laser")
            return
        }
        guard Date().timeIntervalSince(self.lastLaserFired) >= self.ship.laserRecharge else {
            self.sendMessage(message: "Laser not ready")
            return
        }
        self.repair = false
        self.lastLaserFired = Date()
        self.fuel -= Int(self.ship.laserCost)
        self.wtmp += Int(self.ship.laserCost) / 10
        self.laser.fire(directionNetrek: direction, shooter: self)
    }
    func fireTorpedo(direction: Double) {
        guard self.weaponsOverheated == false else {
            self.sendMessage(message: "Weapons overheated!")
            return
        }
        guard self.cloak == false else {
            self.sendMessage(message: "Cannot fire while cloaked")
            return
        }
        guard let torpedo = self.torpedoes.first(where: { $0.state == .free }) else {
            self.sendMessage(message: "You may only fire up to \(self.torpedoes.count) torpedoes at a time")
            return
        }
        guard self.fuel >= Int(self.ship.torpCost) else {
            self.sendMessage(message: "You do not have enough fuel to fire a torpedo")
            return
        }
        guard Date().timeIntervalSince(self.lastTorpedoFired) > 0.09 else {
            self.sendMessage(message: "Still reloading torpedo")
            return
        }
        self.repair = false
        self.lastTorpedoFired = Date()
        self.fuel -= Int(self.ship.torpCost)
        self.wtmp += Int(self.ship.torpCost) / 10
        torpedo.fire(player: self, direction: direction)
    }
    func firePlasma(direction: Double) {
        guard self.plasmaEquipped else {
            self.sendMessage(message: "This ship is not equipped with Plasma")
            return
        }
        guard self.weaponsOverheated == false else {
            self.sendMessage(message: "Weapons overheated!")
            return
        }
        guard self.cloak == false else {
            self.sendMessage(message: "Cannot fire while cloaked")
            return
        }
        guard plasma.state == .free else {
            self.sendMessage(message: "You may only fire one plasma at a time")
            return
        }
        guard self.fuel >= Int(self.ship.plasmaCost) else {
            self.sendMessage(message: "You do not have enough fuel to fire a plasma")
            return
        }
        self.repair = false
        self.fuel -= Int(self.ship.plasmaCost)
        self.wtmp += Int(self.ship.plasmaCost) / 10
        //only starbases can fire plasma in any direction
        if self.ship == .starbase {
            plasma.fire(player: self, direction: direction)
        } else {
            plasma.fire(player: self, direction: self.direction)
        }
    }

    deinit {
        debugPrint("Player \(slot) deinit")
    }
    func robotConnected(robot: Robot) {
        self.robot = robot
        self.status = .outfit
    }
    func connected(context: ChannelHandlerContext) {
        self.context = context
        self.status = .outfit
        self.remoteAddress = context.remoteAddress
        
        do {
            debugPrint("sending SP MOTD")
            let data = MakePacket.spMotd(motd: "Experimental Swift Netrek Server version 0.3-alpha feedback@networkmom.net")
            context.eventLoop.execute {
                let buffer = context.channel.allocator.buffer(bytes: data)
                _ =  context.channel.writeAndFlush(buffer)
            }
        }

        //TODO implement queue
        self.sendSpYou()
    }

    
    /*func connected(connection: ServerConnection) {
        self.connection = connection
        self.status = .outfit
        
        do {
            debugPrint("sending SP MOTD")
            let data = MakePacket.spMotd(motd: "Experimental Swift Netrek Server")
            connection.send(data: data)
        }

        //TODO implement queue
        self.sendSpYou()
    }*/
    func activateCloak(_ newStatus: Bool) {
        guard self.status == .alive else {
            return
        }
        if newStatus {
            self.cloak = true
        } else {
            self.cloak = false
        }
    }
    func sendSpYou() {
        let data = MakePacket.spYou(player: self)
        debugPrint("sending SP_YOU")
        if let context = context {
            context.eventLoop.execute {
                    let buffer = context.channel.allocator.buffer(bytes: data)
                    _ = context.channel.writeAndFlush(buffer)
            }
        }

        //self.connection?.send(data: data)
    }
    func sendMessage(message: String, from: UInt8? = nil) {
        let data: Data
        if let from = from {
            data = MakePacket.spMessage(message: message, from: from)
        } else {
            //if from not specified, set to 255
            //which means from server
            data = MakePacket.spMessage(message: message, from: 255)
        }
        if let context = context {
            context.eventLoop.execute {
                let buffer = context.channel.allocator.buffer(bytes: data)
                _ = context.channel.writeAndFlush(buffer)
            }
        }

        //connection?.send(data: data)
    }
    func planetLockDirection() {
        guard let planet = self.planetLock else {
            return
        }
        self.helmDirection = atan2(-1 * (planet.positionY - self.positionY), planet.positionX - self.positionX)
    }
    func playerLockDirection() {
        guard let player = self.playerLock else {
            return
        }
        self.helmDirection = atan2(-1 * (player.positionY - self.positionY), player.positionX - self.positionX)
    }
    func receivedCpTractor(state: Int, target: Int, mode: TractorMode) {
        guard state == 1 else { // state 0 means off
            self.tractorMode = .off
            self.tractor = nil
            self.sendMessage(message: "Tractor Beam Off")
            return
        }
        guard let target = universe.players[safe: target] else {
            self.sendMessage(message: "Unable to identify tractor beam target")
            return
        }
        guard target.status == .alive else {
            self.sendMessage(message: "Invalid tractor beam target \(target.team.letter)\(target.slot)")
            return
        }
        //check range
        guard checkTractorRange(target: target) else {
            self.sendMessage(message: "\(target.team.letter)\(target.slot) is out of tractor beam range")
            return
        }
        self.tractor = target
        self.tractorMode = mode
    }
    func checkTractorRange(target: Player) -> Bool {
        if (self.positionX - target.positionX) * (self.positionX - target.positionX) + (self.positionY - target.positionY) * (self.positionY - target.positionY) < self.ship.tractorRange * self.ship.tractorRange {
            return true
        } else {
            return false
        }
    }
    func receivedCbBeam(up: Bool) {
        guard self.status == .alive else {
            return
        }
        guard let planet = orbit else {
            self.sendMessage(message: "We must be orbiting a planet to use transporters")
            return
        }
        switch up {
        case true:
            guard planet.team == self.team else {
                self.sendMessage(message: "We cannot beam up enemy troops")
                return
            }
            guard planet.armies > 4 else {
                self.sendMessage(message: "Only \(planet.armies) armies on planet \(planet).  No spare troops to beam up.")
                return
            }
            self.transporter = .beamup
        case false:
            self.transporter = .beamdown
        }
    }
    func receivedCpBomb() {
        guard self.status == .alive else {
            return
        }
        guard let planet = self.orbit else {
            self.sendMessage(message: "You must be orbiting to bomb", from: 255)
            return
        }
        guard planet.team != self.team else {
            self.sendMessage(message: "Traitor! Do not bomb your own planet")
            return
        }
        guard planet.armies > 4 else {
            self.sendMessage(message: "Bombing ineffective: less than 5 armies on the planet")
            return
        }
        self.sendMessage(message: "Initiating orbital bombardment of planet \(planet.name)")
        self.shieldsUp = false
        self.bomb = true
        
        for player in universe.players.filter({$0.status == .alive && $0.team == planet.team}) {
            player.sendMessage(message: "Distress call from \(planet.name): We are being bombed!",from: 255)
        }
    }
    func receivedPlayerLock(playerID: Int) {
        guard self.status == .alive else {
            return
        }
        guard let player = universe.players[safe: playerID], player.slot == playerID, player.status == .alive else {
            self.sendMessage(message: "Unable to lock on to player \(playerID)")
            return
        }
        self.playerLock = player
        self.planetLock = nil
        self.orbit = nil
        playerLockDirection()
        self.sendMessage(message: "Setting intercept course for \(player.user?.name ?? "player \(player.slot)")")
        //let spMessage = MakePacket.spMessage(message: "Setting intercept course for \(player.user?.name ?? "player \(player.slot)")", from: 255)
        //self.connection?.send(data: spMessage)
    }
    func receivedPlanetLock(planetID: Int) {
        guard self.status == .alive else {
            return
        }
        guard let planet = universe.planets[safe: planetID], planet.planetID == planetID else {
            debugPrint("\(#file) \(#function) unable to identify planetID \(planetID)")
            return
        }
        self.planetLock = planet
        self.playerLock = nil
        self.orbit = nil
        planetLockDirection()
        //let spMessage = MakePacket.spMessage(message: "Course set for planet \(planet.name)", from: 255)
        self.sendMessage(message: "Course set for planet \(planet.name)")
        //self.connection?.send(data: spMessage)
    }
    func receivedDetMyTorp() {
        guard self.status == .alive else {
            return
        }
        for torpedo in self.torpedoes {
            torpedo.detMyTorp()
        }
    }
    func receivedDetTorp() {
        guard self.status == .alive else {
            return
        }
        guard self.fuel >= self.ship.detCost else {
            self.sendMessage(message: "Not enough fuel to detonate torps")
            return
        }
        guard self.weaponsOverheated == false else {
            self.sendMessage(message: "Weapons overheated!")
            return
        }
        self.wtmp += self.ship.detCost / 5
        for player in universe.players.filter({$0.status != .free && $0.team != self.team}) {
            for torpedo in player.torpedoes.filter({$0.state == .alive}) {
                guard (torpedo.positionX - self.positionX) * (torpedo.positionX - self.positionX) + (torpedo.positionY - self.positionY) * (torpedo.positionY - self.positionY) < Player.detDist * Player.detDist else {
                    continue
                }
                torpedo.explode()
            }
        }
    }
    func receivedCpRefit(ship: ShipType) {
        guard let homeworld = universe.homeworld[self.team] else {
            self.sendMessage(message: "Unexpected server error: I cannot identify your homeworld")
            return
        }
        guard let orbit = self.orbit, orbit === homeworld else {
            self.sendMessage(message: "You must be orbiting your homeworld to change ships")
            return
        }
        guard self.armies == 0 else {
            self.sendMessage(message: "You must beam your armies down before being transported to your new ship")
            return
        }
        guard self.shield >= self.ship.maxShield * 0.75, self.damage <= self.ship.maxDamage * 0.25, self.fuel >= self.ship.maxFuel * 3 / 4 else {
            self.sendMessage(message: "Central command refuses to accept a ship in this condition!")
            return
        }
        if ship == .starbase {
            guard nil == universe.players.first(where: { $0.team == self.team && $0.status == .alive && $0.ship == .starbase}) else {
                self.sendMessage(message: "Your team already has a starbase!")
                return
            }
            guard self.kills >= 2.0 else {
                self.sendMessage(message: "You must have 2 kills to be reassigned to a starbase")
                return
            }
        }
        self.sendMessage(message: "You are being transported to your new vessel")
        self.ship = ship
        self.fuel = self.ship.maxFuel
        self.damage = 0
        self.shield = ship.maxShield
        self.etmp = 0
        self.wtmp = 0
        
        switch self.ship {
        case .scout, .assault:
            self.plasmaEquipped = false
        case .starbase:
            self.plasmaEquipped = true
        case .destroyer,.cruiser,.battleship:
            if self.kills >= 2.0 {
                self.plasmaEquipped = true
            } else {
                self.plasmaEquipped = false
            }
        }
        self.refitting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.refitting = false
            self.sendMessage(message: "Oh no!  Not you!")
        }
    }
    func receivedCpOutfit(team: Team, ship: ShipType) -> Bool {
        
        /*guard team == universe.team1 || team == universe.team2 else {
            
            //let data1 = MakePacket.spMessage(message: "I cannot allow that.  Pick another team or ship", from: 255)
            self.sendMessage(message: "I cannot allow that.  Pick another team or ship")
            //connection?.send(data: data1)
            
            let data2 = MakePacket.spPickOk(false)
            if let context = context {
                context.eventLoop.execute {
                    let buffer = context.channel.allocator.buffer(bytes: data2)
                    _ = context.channel.writeAndFlush(buffer)
                }
            }

            //connection?.send(data: data2)
            return false
        }*/
        guard self.status == .outfit || self.status == .dead else {
            //let data = MakePacket.spMessage(message: "Outfiting ship not available in state \(self.status.rawValue)", from: 255)
            self.sendMessage(message: "Outfiting ship not available in state \(self.status.rawValue)")
            //connection?.send(data: data)
            
            let data2 = MakePacket.spPickOk(false)
            if let context = context {
                context.eventLoop.execute {
                    let buffer = context.channel.allocator.buffer(bytes: data2)
                    _ = context.channel.writeAndFlush(buffer)
                }
            }

            //connection?.send(data: data2)
            return false
        }
        guard ship != .starbase else {
            self.sendMessage(message: "You need at least 2 kills then refit at your homeworld to launch a starbase")
            let data2 = MakePacket.spPickOk(false)
            if let context = context {
                context.eventLoop.execute {
                    let buffer = context.channel.allocator.buffer(bytes: data2)
                    _ = context.channel.writeAndFlush(buffer)
                }
            }
            return false
        }
        guard let homeworld = universe.homeworld[team] else {
            debugPrint("\(#file) \(#function) error unable to identify homeworld for team \(team)")
            //let data = MakePacket.spMessage(message: "Unexpected server error, cannot find homeworld", from: 255)
            self.sendMessage(message: "Unexpected server error, cannot find homeworld")
            //connection?.send(data: data)

            let data2 = MakePacket.spPickOk(false)
            if let context = context {
                context.eventLoop.execute {
                    let buffer = context.channel.allocator.buffer(bytes: data2)
                    _ = context.channel.writeAndFlush(buffer)
                }
            }

            //connection?.send(data: data2)

            return false
        }
        self.team = team
        self.newShip(ship: ship)
        self.positionX = homeworld.positionX + Double.random(in: -5000 ..< 5000)
        self.positionY = homeworld.positionY + Double.random(in: -5000 ..< 5000)
        //let data = MakePacket.spMessage(message: "Admiralty: we expect all sentients to do their duty", from: 255)
        //connection?.send(data: data)
        self.sendMessage(message: "Admiralty: we expect all sentients to do their duty!")

        let data2 = MakePacket.spPickOk(true)
        if let context = context {
            context.eventLoop.execute {
                let buffer = context.channel.allocator.buffer(bytes: data2)
                _ = context.channel.writeAndFlush(buffer)
            }
        }

        return true
        //connection?.send(data: data2)
    }
    func receivedCpSpeed(speed: Int) {
        guard self.status == .alive else {
            return
        }
        guard self.enginesOverheated == false else {
            self.sendMessage(message: "Engines still overheated!")
            return
        }
        guard speed >= 0 && speed <= 100 else {
            debugPrint("\(#file) \(#function) received invalid speed \(speed)")
            return
        }
        self.helmSpeed = min(Double(speed),self.ship.maxSpeed)
        self.orbit = nil
    }
    //this direction is in Legacy Netrek Direction
    func receivedCpDirection(netrekDirection: Int) {
        guard self.status == .alive else {
            return
        }
        guard netrekDirection >= 0 && netrekDirection < 256 else {
            debugPrint("\(#file) \(#function) received invalid direction \(netrekDirection)")
            return
        }
        self.receivedDirection(direction: NetrekMath.directionNetrek2Radian(netrekDirection))
    }
    //this direction is in radians
    func receivedDirection(direction: Double) {
        self.helmDirection = direction
        self.orbit = nil
        self.planetLock = nil
    }
    
    func receivedCpShield(up: Bool) {
        if up {
            self.shieldsUp = true
        } else {
            self.shieldsUp = false
        }
    }
    func receivedCpLogin(name: String, password: String, userinfo: String) {
        guard self.status == .outfit else {
            debugPrint("Error: \(#file) \(#function) slot \(self.slot) state \(self.status) unexpected cpLogin")
            return
        }
        if name.starts(with: "guest") {
            let guestName = "guest\(User.guestID)"
            User.guestID += 1
            let user = User(name: guestName, password: password, userinfo: userinfo)
            universe.users.append(user)
            self.user = user
        } else if let existingUser = universe.users.first(where: {$0.name == name}) {
            guard existingUser.password == password else {
                debugPrint("Sending SP_LOGIN failure to player \(self.slot)")
                //let message = MakePacket.spMessage(message: "Incorrect password for existing user \(name)", from: 255)
                self.sendMessage(message: "Incorrect password for existing user \(name)")
                //connection?.send(data: message)
                let spLogin = MakePacket.spLogin(success: false)
                if let context = context {
                    context.eventLoop.execute {
                        let buffer = context.channel.allocator.buffer(bytes: spLogin)
                        _ = context.channel.writeAndFlush(buffer)
                    }
                }

                //connection?.send(data: spLogin)
                return
            }
            self.user = existingUser
        } else {
            // create new user
            let user = User(name: name, password: password, userinfo: userinfo)
            universe.users.append(user)
            self.user = user
        }
            
        let data = MakePacket.spLogin(success: true)
        debugPrint("Sending SP_LOGIN success to player \(self.slot)")
        if let context = context {
            context.eventLoop.execute {
                let buffer = context.channel.allocator.buffer(bytes: data)
                _ = context.channel.writeAndFlush(buffer)
            }
        }

        //connection?.send(data: data)
        
        self.sendInitialTransfer()
        self.sendPlanetLoc()
        self.sendSpMask()
    }
    
    // sent during initial transfer
    func sendPlanetLoc() {
        for planet in universe.planets {
            let data = MakePacket.spPlanetLoc(planet: planet)
            debugPrint("Sending SP_PLANET_LOC for planet \(planet.planetID) to \(self.slot)")
            if let context = context {
                context.eventLoop.execute {
                    let buffer = context.channel.allocator.buffer(bytes: data)
                    _ = context.channel.writeAndFlush(buffer)
                }
            }

            //connection?.send(data: data)
        }
    }
    
    func reverseDirectionX() {
        switch self.direction {
        case 0 ..< Double.pi / 2:
            self.direction = Double.pi / 2 + (Double.pi / 2 - self.direction)
        case Double.pi / 2 ..< Double.pi:
            self.direction = Double.pi / 2 - (self.direction - (Double.pi / 2))
        case Double.pi ..< Double.pi * 3 / 2:
            self.direction = Double.pi * 2 - (self.direction - Double.pi)
        case Double.pi * 3 / 2 ..< Double.pi * 2:
            self.direction = Double.pi + (2 * Double.pi - self.direction)
        default:
            debugPrint("\(#file) \(#function) unexpected direction \(self.direction)")
        }
    }
    func reverseDirectionY() {
        switch self.direction {
        case 0 ..< Double.pi:
            self.direction = Double.pi * 2 - self.direction
        case Double.pi ..< 2 * Double.pi:
            self.direction = Double.pi - (self.direction - Double.pi)
        default:
            debugPrint("\(#file) \(#function) unexpected direction \(self.direction)")
        }
    }
    func updateOrbit() {
        guard let orbit = self.orbit else {
            // should never get here
            debugPrint("\(#file) \(#function) unexpected orbit error")
            return
        }
        self.orbitRadian -= 0.1
        self.positionX = orbit.positionX + cos(self.orbitRadian) * Player.orbitRadius
        self.positionY = orbit.positionY - sin(self.orbitRadian) * Player.orbitRadius
        self.direction = self.orbitRadian - (Double.pi / 2)
    }
    func updatePosition() {
        guard self.orbit == nil else {
            self.updateOrbit()
            return
        }
        self.etmp += Int(self.speed)
        
        positionX += Globals.WARP1 * Double(self.speed) * cos(direction)
        positionY -= Globals.WARP1 * Double(self.speed) * sin(direction)
        
        if positionX < 0  {
            positionX = -positionX
            reverseDirectionX()
            self.helmDirection = self.direction
        }
        if positionX > Globals.GalaxyWidth {
            positionX = Globals.GalaxyWidth - (positionX - Globals.GalaxyWidth)
            reverseDirectionX()
            self.helmDirection = self.direction
         }
        
        if positionY < 0 {
            positionY = -positionY
            reverseDirectionY()
            self.helmDirection = self.direction
        }
        if positionY > Globals.GalaxyWidth {
            positionY = Globals.GalaxyWidth - (positionY - Globals.GalaxyWidth)
            reverseDirectionY()
            self.helmDirection = self.direction
        }
        
        
    }
    func sendSpMask() {
        let data = MakePacket.spMask(universe: universe)
        if let context = context {
            context.eventLoop.execute {
                let buffer = context.channel.allocator.buffer(bytes: data)
                _ = context.channel.writeAndFlush(buffer)
            }
        }
        //connection?.send(data: data)
        debugPrint("Sending SP_MASK to player \(self.slot)")
    }
    
    func updateDirection() {
        guard helmDirection != direction else {
            //nothing to do
            return
        }
        guard speed >= 1 else {
            self.direction = self.helmDirection
            return
        }
        let maxChange = self.ship.turnSpeed / (self.speed * self.speed)
        
        debugPrint("maxChange \(maxChange)")
        let helmDiff = self.helmDirection - self.direction
        
        if abs(helmDiff) < maxChange {
            self.direction = self.helmDirection
            return
        }
        if helmDiff < Double.pi && helmDiff > 0 {
            self.direction = self.direction + maxChange
            return
        }
        if helmDiff > -Double.pi && helmDiff < 0 {
            self.direction = self.direction - maxChange
            return
        }
        if helmDiff >= Double.pi {
            self.direction -= maxChange
            return
        }
        if helmDiff <= -Double.pi {
            self.direction += maxChange
            return
        }
        debugPrint("\(#file) \(#function) error helmDirection \(helmDirection) directionNetrek \(directionNetrek)")
    }
    private func playerLockSpeed() {
        //only adjust speed for friendly starbase
        if let playerLock = self.playerLock {
            guard playerLock.team == self.team, playerLock.ship == .starbase else {
                return
            }
            //if we are getting close to our locked planet, decrease speed
            let distance = sqrt((playerLock.positionY - self.positionY) * (playerLock.positionY - self.positionY) + (playerLock.positionX - self.positionX) * (playerLock.positionX - self.positionX))
            switch distance {
            case 0 ..< Player.orbitRange:
                self.helmSpeed = min(self.helmSpeed, 2)
                if self.speed <= 2 {
                    //TODO DOCK with SB
                    //self.enterOrbit()
                }
            case Player.orbitRange ..< Player.orbitRange * 2:
                self.helmSpeed = min(self.helmSpeed, 3)
            case Player.orbitRange * 2 ..< Player.orbitRange * 3:
                self.helmSpeed = min(self.helmSpeed, 4)
            case Player.orbitRange * 3 ..< Player.orbitRange * 5:
                    self.helmSpeed = min(self.helmSpeed, 5)
            default:
                break
            }
        }
    }

    private func planetLockSpeed() {
        if let planetLock = self.planetLock {
            //if we are getting close to our locked planet, decrease speed
            let distance = sqrt((planetLock.positionY - self.positionY) * (planetLock.positionY - self.positionY) + (planetLock.positionX - self.positionX) * (planetLock.positionX - self.positionX))
            switch distance {
            case 0 ..< Player.orbitRange:
                self.helmSpeed = min(self.helmSpeed, 2)
                if self.speed <= 2 {
                    self.enterOrbit()
                }
            case Player.orbitRange ..< Player.orbitRange * 2:
                self.helmSpeed = min(self.helmSpeed, 3)
            case Player.orbitRange * 2 ..< Player.orbitRange * 3:
                self.helmSpeed = min(self.helmSpeed, 4)
            case Player.orbitRange * 3 ..< Player.orbitRange * 5:
                    self.helmSpeed = min(self.helmSpeed, 5)
            default:
                break
            }
        }
    }
    func updateSpeed() {
        if planetLock != nil {
            self.planetLockSpeed()
        }
        if playerLock != nil {
            self.playerLockSpeed()
        }
        let targetSpeed: Double
        if helmSpeed > maxSpeed {
            targetSpeed = maxSpeed
        } else {
            targetSpeed = helmSpeed
        }
        guard targetSpeed != speed else {
            return
        }
        if targetSpeed < speed {
            self.speed = self.speed - self.ship.acceleration
            if self.speed < 0 {
                self.speed = 0
            }
            if self.speed < targetSpeed {
                self.speed = targetSpeed
            }
            return
        }
        if targetSpeed > speed {
            self.speed = speed + self.ship.acceleration
            if self.speed > targetSpeed {
                self.speed = targetSpeed
            }
            return
        }
    }
    func updateFuel() {
        if fuel < Int(self.speed) * self.ship.warpCost {
            let reducedSpeed = Double(Int(self.ship.recharge / self.ship.warpCost) - 1)
            if reducedSpeed < self.speed {
                self.speed = reducedSpeed
                self.helmSpeed = reducedSpeed
            }
        }
        self.fuel += self.ship.recharge - Int(self.speed) * self.ship.warpCost
        if self.shieldsUp {
            if fuel < self.ship.shieldCost {
                let reducedSpeed = Double(Int(self.ship.recharge / self.ship.warpCost) - 2)
                if reducedSpeed < self.speed {
                    self.speed = reducedSpeed
                    self.helmSpeed = reducedSpeed
                }
            }
            self.fuel -= self.ship.shieldCost
        }
        if self.cloak {
            if fuel < self.ship.cloakCost {
                self.cloak = false
                self.sendMessage(message: "Cloak failed due to fuel shortage")
            }
            self.fuel -= self.ship.cloakCost
        }
    }
    func updateRepair() {
        var repairRate = self.ship.repair
        if self.repair {
            repairRate *= 2.0
        }
        if self.damage > 0 && self.shieldsUp == false {
            self.damage -= repairRate
        }
        if self.damage
            < 0 {
            self.damage = 0
        }
        if self.shield < self.ship.maxShield {
            self.shield += repairRate * 2
        }
        if self.shield > self.ship.maxShield {
            self.shield = self.ship.maxShield
        }
        if self.shield >= self.ship.maxShield && self.damage <= 0 {
            self.repair = false
        }
    }
    func receivedRepair(_ newState: Bool) {
        if newState == false {
            self.repair = false
        } else {
            self.repair = true
            self.helmSpeed = 0.0
            self.shieldsUp = false
        }
    }
    func bombTick() {
        guard self.bomb == true else {
            //should not have gotten here
            return
        }
        guard let planet = orbit else {
            //should not have gotten here either
            return
        }
        guard planet.team != self.team else {
            return
        }
        guard planet.armies > 4 else {
            self.bomb = false
            self.sendMessage(message: "Bombing ineffective: only \(planet.armies) armies left")
            return
        }
        let random = Int.random(in: 0 ..< 100)
        var damage = 0
        switch random {
        case 0 ..< 50:
            // no damage
            return
        case 50 ..< 80:
            damage = 1
        case 80 ..< 90:
            damage = 2
        case 90 ..< 100:
            damage = 3
        default:
            debugPrint("Unexpected bombing result \(random)")
        }
        if self.ship == .assault {
            damage += 1
        }
        planet.armies -= damage
        if planet.armies < 0 {
            planet.armies = 0
        }
        self.sendMessage(message: "Bombardment continues \(planet.armies) armies left", from: 255)
        self.kills += 0.02 * Double(damage)
        if let user = user {
            
            //update stats
            switch universe.gameState {
            case .intramural:
                user.intramuralArmies += damage
            case .tmode:
                user.tArmies += damage
            }
        }
    }
    private func beam() {
        //TODO limit army capacity
        
        // every 0.8 seconds by shortTimer
        guard let planet = self.orbit else {
            self.transporter = .off
            self.sendMessage(message: "Left orbit, terminating transport")
            return
        }
        switch self.transporter {
        case .off:
            return
        case .beamup:
            guard planet.team == self.team else {
                self.sendMessage(message: "We cannot beam up enemy troops")
                self.transporter = .off
                return
            }
            guard planet.armies > 4 else {
                self.sendMessage(message: "Only \(planet.armies) armies on planet \(planet.name).  No spare troops to beam up.")
                self.transporter = .off
                return
            }
            guard self.armies < self.maxArmies else {
                self.sendMessage(message: "Can only carry \(self.maxArmies) armies.  Have \(self.armies) on board")
                self.transporter = .off
                return
            }
            planet.armies -= 1
            self.armies += 1
            self.sendMessage(message: "Planet \(planet.armies) armies.  Ship \(self.armies) armies.")
        case .beamdown:
            guard self.armies > 0 else {
                self.sendMessage(message: "No more troops to beam down")
                self.transporter = .off
                return
            }
            self.armies -= 1
            planet.beamDownArmy(player: self)
            //for this case message handled by planet.beamDownArmy
        }
    }
    func updateTractor() {
        guard self.tractorMode != .off else { return }
        guard let target = tractor else { return }
        guard checkTractorRange(target: target) == true else {
            self.tractorMode = .off
            self.tractor = nil
            self.sendMessage(message: "Tractor target moved out of range")
            return
        }
        guard target.status == .alive else {
            self.tractorMode = .off
            self.tractor = nil
            self.sendMessage(message: "Tractor target destroyed")
            return
        }
        if self.enginesOverheated {
            self.tractorMode = .off
            self.tractor = nil
            self.sendMessage(message: "Engines overheated: disabling tractor beam")
            return
        }
        guard self.fuel >= Player.tractorCost else {
            self.tractorMode = .off
            self.tractor = nil
            self.sendMessage(message: "Insufficient fuel for tractor beam")
            return
        }
        self.fuel -= Player.tractorCost
        self.etmp += Player.tractorHeat
        self.orbit = nil
        target.orbit = nil
        
        let halfTractorForce = Globals.WARP1 * self.ship.tractorStrength
        var myVectorDirection = atan2((target.positionY - self.positionY) * -1, target.positionX - self.positionX)
        if self.tractorMode == .pressor {
            myVectorDirection = myVectorDirection * -1
        }
        self.positionX += halfTractorForce / self.ship.mass * cos(myVectorDirection)
        self.positionY += halfTractorForce / self.ship.mass * sin(myVectorDirection) * -1

        let targetVectorDirection = myVectorDirection + Double.pi
        target.positionX += halfTractorForce / target.ship.mass * cos(targetVectorDirection)
        target.positionY += halfTractorForce / target.ship.mass * sin(targetVectorDirection) * -1
        
    }
    
    func planetAttack() {
        for planet in universe.planets.filter({$0.team != self.team && $0.team != .independent}) {
            if (planet.positionX - self.positionX) * (planet.positionX - self.positionX) + (planet.positionY - self.positionY) * (planet.positionY - self.positionY) < Player.planetRange * Player.planetRange {
                let damage = 2 + planet.armies / 10
                self.impact(damage: Double(damage), planet: planet, whyDead: .planet)
            }
        }
    }
    func shortTimerFired() {
        //executed ten times per second
        if universe.gameState == .tmode {
            self.user?.tournamentTicks += 1
        }
        
        if self.status == .alive {
            //every half second
            if universe.timerCount % 5 == 0 && self.orbit != nil && self.bomb {
                self.bombTick()
            }
            if universe.timerCount % 5 == 0 {
                self.planetAttack()
            }
            
            //army beaming every 0.8 seconds
            if universe.timerCount % 8 == 0 && self.transporter != .off {
                self.beam()
            }
            self.wtmp -= self.ship.weaponCoolRate
            self.etmp -= self.ship.engineCoolRate
            self.updateRepair()
            self.updateFuel()
            self.updateSpeed()
            self.updateDirection()
            self.updatePosition()
            self.updateTractor()
        }
        sendSpYou()
        for player in universe.players {
            if player.status == .alive || player.status == .explode {
                self.sendSpPlayer(player: player)
            }
        }
        for torpedo in self.torpedoes {
            torpedo.shortTimerFired()
        }
        plasma.shortTimerFired()
    }
    
    func sendSpStats() {
        //this sends this players stats to all players
        if let spStats = MakePacket.spStats(player: self) {
            for player in self.universe.players {
                if let context = player.context {
                    context.eventLoop.execute {
                        let buffer = context.channel.allocator.buffer(bytes: spStats)
                        _ = context.channel.writeAndFlush(buffer)
                    }
                }

                //player.connection?.send(data: spStats)
            }
        }
    }
    func minuteTimerFired() {
        self.sendSpStats()
    }
    
    func secondTimerFired() {
        //execute one time per second
        self.robot?.secondTimerFired()
        
        if planetLock != nil {
            self.planetLockDirection()
        }
        if playerLock != nil {
            self.playerLockDirection()
        }
        for player in universe.players {
            if player.status == .alive || player.status == .explode {
                self.sendSpPlLogin(player: player)
                self.sendSpHostile(player: player)
                self.sendSpPlayerInfo(player: player)
                self.sendSpKills(player: player)
                self.sendSpPlayerStatus(player: player)
                self.sendSpFlags(player: player)
            }
        }
    }
    func sendSpPlanets() {
        for planet in universe.planets {
            self.sendSpPlanet(planet: planet)
        }
     }
    func sendSpPlanet(planet: Planet) {
        let data = MakePacket.spPlanet(planet: planet)
        debugPrint("Sending SP_PLANET for planet \(planet.planetID) to \(self.slot)")
        if let context = context {
            context.eventLoop.execute {
                let buffer = context.channel.allocator.buffer(bytes: data)
                _ = context.channel.writeAndFlush(buffer)
            }
        }
        //connection?.send(data: data)
    }
    
    func sendSpHostile(player: Player) {
        let data = MakePacket.spHostile(player: player)
        debugPrint("Sending SP_HOSTILE for player \(player.slot) to \(self.slot)")
        if let context = context {
            context.eventLoop.execute {
                let buffer = context.channel.allocator.buffer(bytes: data)
                _ = context.channel.writeAndFlush(buffer)
            }
        }
        //connection?.send(data: data)
    }
    func sendSpPlLogin(player: Player) {
        let data = MakePacket.spPlLogin(player: player)
        debugPrint("Sending SP_PL_LOGIN for player \(player.slot) to \(self.slot)")
        if let context = context {
            context.eventLoop.execute {
                let buffer = context.channel.allocator.buffer(bytes: data)
                _ = context.channel.writeAndFlush(buffer)
            }
        }
        //connection?.send(data: data)
    }
    func sendSpPlayerInfo(player: Player) {
        let data = MakePacket.spPlayerInfo(player: player)
        debugPrint("Sending SP_PLAYER_INFO 2 for player \(player.slot) to \(self.slot)")
        if let context = context {
            context.eventLoop.execute {
                let buffer = context.channel.allocator.buffer(bytes: data)
                _ = context.channel.writeAndFlush(buffer)
            }
        }
        //connection?.send(data: data)
    }
    func sendSpKills(player: Player) {
        let data = MakePacket.spKills(player: player)
        debugPrint("Sending SP_KILLS_2 for player \(player.slot) to \(self.slot)")
        if let context = context {
            context.eventLoop.execute {
                let buffer = context.channel.allocator.buffer(bytes: data)
                _ = context.channel.writeAndFlush(buffer)
            }
        }
        //connection?.send(data: data)
    }
    func sendSpFlags(player: Player) {
        let data = MakePacket.spFlags(player: player)
        debugPrint("Sending SP_Flags for player \(player.slot) to \(self.slot)")
        if let context = context {
            context.eventLoop.execute {
                let buffer = context.channel.allocator.buffer(bytes: data)
                _ = context.channel.writeAndFlush(buffer)
            }
        }
        //connection?.send(data: data)
    }
    // full transfer sent after CP_LOGIN
    func sendInitialTransfer() {
        for player in self.universe.players {
            self.sendSpPlLogin(player: player)
            self.sendSpHostile(player: player)
            self.sendSpPlayerInfo(player: player)
            self.sendSpKills(player: player)
            self.sendSpPlayerStatus(player: player)
            self.sendSpFlags(player: player)
            self.sendSpPlayer(player: player)
            self.sendSpPlanets()
        }
    }
    func sendSpPlayerStatus(player: Player) {
        let data = MakePacket.spPStatus(player: player)
        debugPrint("Sending SP_PStatus for player \(player.slot) to \(self.slot)")
        if let context = context {
            context.eventLoop.execute {
                let buffer = context.channel.allocator.buffer(bytes: data)
                _ = context.channel.writeAndFlush(buffer)
            }
        }
        //connection?.send(data: data)
    }
    func sendSpPlayer(player: Player) {
        let data = MakePacket.spPlayer(player: player)
        debugPrint("Sending SP_Player for player \(player.slot) to \(self.slot)")
        if let context = context {
            context.eventLoop.execute {
                let buffer = context.channel.allocator.buffer(bytes: data)
                _ = context.channel.writeAndFlush(buffer)
            }
        }
        //connection?.send(data: data)
    }
}
