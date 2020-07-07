//
//  Laser.swift
//  NetrekServer
//
//  Created by Darrell Root on 7/1/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import Foundation

enum LaserStatus: UInt8 {
    case free = 0
    case hit = 1
    case miss = 2
    case hitPhoton = 3
}
class Laser {
    static let baseRange = 6000.0
    static let zapPlayer = 390.0
    static let zapPlasma = 270.0
    
    var laserID: Int = 0
    var direction: Double = 0
    var status = LaserStatus.free
    var positionX: Double = 0.0
    var positionY: Double = 0.0
    var target: Int? = nil
    var universe: Universe
    weak var player: Player? = nil // set by parent after initialization
    
    init(universe: Universe) {
        self.universe = universe
        //self.player set by parent after initialization
    }
    
    func fire(directionNetrek: UInt8, shooter: Player) {
        self.laserID = shooter.slot
        self.direction = NetrekMath.directionNetrek2Radian(directionNetrek)
        self.positionX = Double(shooter.positionX)
        self.positionY = Double(shooter.positionY)
        
        let myRange = Laser.baseRange * shooter.ship.laserDamage / 100.0
        // find possible targets
        
        var closestHit: Player? = nil
        var closestRange = 100000.0
        
        for player in universe.players {
            guard player.status == .alive else {
                continue
            }
            guard player.team != shooter.team else {
                continue
            }
            
            // efficient pass to rule out most targets
            guard abs(player.positionX - shooter.positionX) < myRange else {
                continue
            }
            guard abs(player.positionY - shooter.positionY) < myRange else {
                continue
            }
            
            let targetRange = sqrt((player.positionX - shooter.positionX) * (player.positionX - shooter.positionX) + (player.positionY - shooter.positionY) * (player.positionY - shooter.positionY))
            
            guard targetRange < myRange else {
                continue
            }
            
            var playerDirection = atan2(-1 * (player.positionY - shooter.positionY), player.positionX - shooter.positionX)
            if playerDirection < 0 {
                playerDirection = playerDirection + Double.pi * 2
            }
            
            let playerHalfArc = Laser.zapPlayer / targetRange  // radians
            debugPrint("Laser arc \(playerHalfArc) targetRange \(targetRange)")
            // 3 cases, 2 of which deal with origin
            if abs(playerDirection - self.direction) < playerHalfArc || (playerDirection - 0) + (Double.pi * 2 - self.direction) < playerHalfArc || (Double.pi * 2 - playerDirection) + (self.direction) < playerHalfArc {
                // arc is correct, may hit
                if targetRange < closestRange {
                    // closest hit
                    closestRange = targetRange
                    closestHit = player
                }
            }

        }//for player in players
        if let closestHit = closestHit {
            self.target = closestHit.slot
            self.status = .hit
            let damage = shooter.ship.laserDamage * (1.0 - closestRange / myRange)
            debugPrint("Laser myRange \(myRange) closestRange \(closestRange) damage \(damage)")
            closestHit.impact(damage: damage, attacker: self.player, whyDead: .laser)
            let spMessage = MakePacket.spMessage(message: "Laser hit player \(closestHit.slot) for \(Int(damage)) damage", from: 255)
            shooter.connection?.send(data: spMessage)
        } else {
            self.status = .miss
            let spMessage = MakePacket.spMessage(message: "Laser missed", from: 255)
            shooter.connection?.send(data: spMessage)
        }
        let spLaser = MakePacket.spLaser(laser: self)
        for player in universe.players.filter( { $0.status == .alive || $0.status == .explode }) {
            player.connection?.send(data: spLaser)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + shooter.ship.laserRecharge) {
            self.status = .free
            let spLaser = MakePacket.spLaser(laser: self)
            for player in self.universe.players.filter( { $0.status == .alive || $0.status == .explode }) {
                player.connection?.send(data: spLaser)
            }
        }
        
    }// func fire
}
