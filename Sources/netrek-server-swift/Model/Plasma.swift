//
//  Plasma.swift
//  NetrekServer
//
//  Created by Darrell Root on 6/30/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
// 

import Foundation

class Plasma {
    let explosionDistance = 350.0 //triggers plasma explosion
    let damageDistance = 2000.0 //plasma damage range
    let number: Int
    var direction: Double = 0 { // radians
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

    var damage = 30.0
    var state: TorpedoState = .free {
        didSet {
            let spPlasmaInfo = MakePacket.spPlasmaInfo(plasma: self)
            for player in self.universe.players.filter( { $0.status != .free }) {
                if let context = player.context {
                    context.eventLoop.execute {
                        let buffer = context.channel.allocator.buffer(bytes: spPlasmaInfo)
                        _ = context.channel.writeAndFlush(buffer)
                    }
                }
                debugPrint("Sending SPlasmaInfo")
            }
        }
    }
    var team: Team
    weak var player: Player?
    var positionX: Double = 0
    var positionY: Double = 0
    
    var vectorX: Double = 0
    var vectorY: Double = 0
    
    var expiration = Date()
    let universe: Universe
    
    init(universe: Universe, player: Player, number: Int) {
        self.universe = universe
        self.team = player.team
        self.player = player
        self.number = number // player.slot
    }
    
    func reset() {
        self.state = .free
        self.positionX = 0
        self.positionY = 0
        self.vectorX = 0
        self.vectorY = 0
        
    }
    
    func fire(player: Player, direction: Double) {
        self.direction = direction
        self.positionX = player.positionX
        self.positionY = player.positionY
        self.team = player.team
        self.state = .alive
        self.damage = player.ship.plasmaDamage
        
        //let torpRadian = NetrekMath.directionNetrek2Radian(direction)
        
        //let shipRadian = NetrekMath.directionNetrek2Radian(player.directionNetrek)
        var plasmaVectorX = Double(player.ship.plasmaSpeed) * Globals.WARP1 * cos(self.direction) + player.speed * Globals.WARP1 * cos(player.direction)
        var plasmaVectorY = -1 * Double(player.ship.plasmaSpeed) * Globals.WARP1
            * sin(self.direction) + -1 * player.speed * Globals.WARP1 * sin(player.direction)
        
        let plasmaMagnitude = sqrt(plasmaVectorX * plasmaVectorX + plasmaVectorY * plasmaVectorY) / Globals.WARP1
        
        //Max torp speed is warp 20
        if plasmaMagnitude > 20 {
            plasmaVectorX = plasmaVectorX * 20 / plasmaMagnitude
            plasmaVectorY = plasmaVectorY * 20 / plasmaMagnitude
        }
        self.vectorX = plasmaVectorX
        self.vectorY = plasmaVectorY
        
        expiration = Date(timeIntervalSinceNow: player.ship.plasmaFuse)
    }
    
    func updatePosition() {
        self.positionX += self.vectorX
        self.positionY += self.vectorY
        if self.state == .alive {
            if self.positionX <= 0 || self.positionX >= Globals.GalaxyWidth || self.positionY <= 0 || self.positionY >= Globals.GalaxyWidth {
                self.explode()
            }
        }
    }
    func checkForHit() -> Bool {
        for player in universe.players {
            guard player.team != self.team && player.status == .alive else {
                continue
            }
            //efficient check to see if we are close
            guard abs(player.positionX - self.positionX) < explosionDistance && abs(player.positionY - self.positionY) < explosionDistance else {
                continue
            }
            if (player.positionX - self.positionX) * (player.positionX - self.positionX) + (player.positionY - self.positionY) * (player.positionY - self.positionY) < explosionDistance * explosionDistance {
                return true
            }
        }
        return false
    }
    func detMyPlasma() {
        self.state = .free
        let spPlasma = MakePacket.spPlasma(plasma: self)
        for player in universe.players.filter( {$0.status != .free} ) {
            if let context = player.context {
                context.eventLoop.execute {
                    let buffer = context.channel.allocator.buffer(bytes: spPlasma)
                    _ = context.channel.writeAndFlush(buffer)
                    debugPrint("Sending SpPlasma to player \(player.slot)")
                }
            } else {
                debugPrint("failed to send SpPlasma to player \(player.slot)")
            }
            //player.connection?.send(data: spTorp)
        }
    }
    func explode() {
        self.state = .explode
        self.expiration = Date()
        for player in universe.players {
            guard player.team != self.team && player.status == .alive else {
                continue
            }
            //efficient check to see if we are close
            guard abs(player.positionX - self.positionX) < damageDistance && abs(player.positionY - self.positionY) < damageDistance else {
                continue
            }
            let distanceSquared = (player.positionX - self.positionX) * (player.positionX - self.positionX) + (player.positionY - self.positionY) * (player.positionY - self.positionY)
            guard distanceSquared < damageDistance * damageDistance else {
                continue
            }
            if distanceSquared <= damageDistance * damageDistance {
                player.impact(damage: self.damage, attacker: self.player, whyDead: .plasma)
            } else {
                let ratio = Double(1 - (distanceSquared * distanceSquared) / Double(damageDistance * damageDistance))
                player.impact(damage: ratio * Double(damage), attacker: self.player, whyDead: .plasma)
            }
        }
    }
    func shortTimerFired() {
        switch self.state {
            
        case .free:
            return
        case .alive:
            debugPrint("Plasma alive")
            if Date() > self.expiration {
                debugPrint("Plasma expired")
                self.state = .free
                //TODO send update when freeing torps
            }
            self.updatePosition()
            if self.checkForHit() {
                self.explode()
            }
            let spPlasma = MakePacket.spPlasma(plasma: self)
            for player in universe.players.filter( {$0.status != .free} ) {
                if let context = player.context {
                    context.eventLoop.execute {
                        let buffer = context.channel.allocator.buffer(bytes: spPlasma)
                        _ = context.channel.writeAndFlush(buffer)
                    }
                    debugPrint("Sending SpPlasma to player \(player.slot)")
                } else {
                    debugPrint("failed to send SpPlasma to player \(player.slot)")
                }

                //player.connection?.send(data: spTorp)
                //debugPrint("Sending SpTorp")
            }
        case .explode:
            if Date() > self.expiration + 1.0 {
                self.state = .free
                let spPlasma = MakePacket.spPlasma(plasma: self)
                for player in universe.players.filter( {$0.status != .free} ) {
                    if let context = player.context {
                        context.eventLoop.execute {
                            let buffer = context.channel.allocator.buffer(bytes: spPlasma)
                            _ = context.channel.writeAndFlush(buffer)
                            debugPrint("Sending SpPlasma to player \(player.slot)")
                        }
                    } else {
                        debugPrint("failed to send SpPlasma to player \(player.slot)")
                    }
                }
            }
        }
    }
}