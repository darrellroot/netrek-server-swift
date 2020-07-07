//
//  Torpedo.swift
//  NetrekServer
//
//  Created by Darrell Root on 6/30/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
// 

import Foundation

enum TorpedoState {
    case free
    case alive
    case explode
}
class Torpedo {
    let explosionDistance = 350.0 //triggers torp explosion
    let damageDistance = 2000.0 //torp damage range
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
            let spTorpInfo = MakePacket.spTorpInfo(torpedo: self)
            for player in self.universe.players.filter( { $0.status != .free }) {
                player.connection?.send(data: spTorpInfo)
                debugPrint("Sending SPTorpInfo")
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
        self.number = number // 8 * player.slot + torp#
    }
    
    func fire(player: Player, direction: Double) {
        self.direction = direction
        self.positionX = player.positionX
        self.positionY = player.positionY
        self.team = player.team
        self.state = .alive
        self.damage = player.ship.torpDamage
        
        //let torpRadian = NetrekMath.directionNetrek2Radian(direction)
        
        //let shipRadian = NetrekMath.directionNetrek2Radian(player.directionNetrek)
        var torpVectorX = Double(player.ship.torpSpeed) * Globals.WARP1 * cos(self.direction) + player.speed * Globals.WARP1 * cos(player.direction)
        var torpVectorY = -1 * Double(player.ship.torpSpeed) * Globals.WARP1
            * sin(self.direction) + -1 * player.speed * Globals.WARP1 * sin(player.direction)
        
        let torpMagnitude = sqrt(torpVectorX * torpVectorX + torpVectorY * torpVectorY) / Globals.WARP1
        
        //Max torp speed is warp 20
        if torpMagnitude > 20 {
            torpVectorX = torpVectorX * 20 / torpMagnitude
            torpVectorY = torpVectorY * 20 / torpMagnitude
        }
        self.vectorX = torpVectorX
        self.vectorY = torpVectorY
        
        expiration = Date(timeIntervalSinceNow: player.ship.torpFuse)
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
    func detMyTorp() {
        self.state = .free
        let spTorp = MakePacket.spTorp(torpedo: self)
        for player in universe.players.filter( {$0.status != .free} ) {
            player.connection?.send(data: spTorp)
            debugPrint("Sending SpTorp")
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
                player.impact(damage: self.damage, attacker: self.player, whyDead: .torpedo)
            } else {
                let ratio = Double(1 - (distanceSquared * distanceSquared) / Double(damageDistance * damageDistance))
                player.impact(damage: ratio * Double(damage), attacker: self.player, whyDead: .torpedo)
            }
        }
    }
    func shortTimerFired() {
        switch self.state {
            
        case .free:
            return
        case .alive:
            debugPrint("Torp alive")
            if Date() > self.expiration {
                debugPrint("Torp expired")
                self.state = .free
                //TODO send update when freeing torps
            }
            self.updatePosition()
            if self.checkForHit() {
                self.explode()
            }
            let spTorp = MakePacket.spTorp(torpedo: self)
            for player in universe.players.filter( {$0.status != .free} ) {
                player.connection?.send(data: spTorp)
                debugPrint("Sending SpTorp")
            }
        case .explode:
            if Date() > self.expiration + 1.0 {
                self.state = .free
                let spTorp = MakePacket.spTorp(torpedo: self)
                for player in universe.players.filter( {$0.status != .free} ) {
                    player.connection?.send(data: spTorp)
                    debugPrint("Sending SpTorp")
                }
            }
        }
    }
}
