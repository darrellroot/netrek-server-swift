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
    case hitPhoton = 4
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
    var targetPositionX: Double = 0.0
    var targetPositionY: Double = 0.0
    var target: Int? = nil
    weak var player: Player? = nil // set by parent after initialization
    
    init() {
        //self.player set by parent after initialization
    }
    
    func fire(directionNetrek: UInt8, shooter: Player) {
        self.laserID = shooter.slot
        self.direction = NetrekMath.directionNetrek2Radian(directionNetrek)
        self.positionX = Double(shooter.positionX)
        self.positionY = Double(shooter.positionY)
        
        let myRange = Laser.baseRange * shooter.ship.laserDamage / 100.0
        // find possible targets
        
        var closestPlayerHit: Player? = nil
        var closestPlayerRange = 100000.0
        var closestPlasmaRange = 100000.0
        var closestPlasmaHit: Plasma? = nil
        
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
            logger.trace("Laser arc \(playerHalfArc) targetRange \(targetRange)")
            // 3 cases, 2 of which deal with origin
            if abs(playerDirection - self.direction) < playerHalfArc || (playerDirection - 0) + (Double.pi * 2 - self.direction) < playerHalfArc || (Double.pi * 2 - playerDirection) + (self.direction) < playerHalfArc {
                // arc is correct, may hit
                if targetRange < closestPlayerRange {
                    // closest hit
                    closestPlayerRange = targetRange
                    closestPlayerHit = player
                }
            }
        }//for player in players
        
        for player in universe.players {
            guard let plasma = player.plasma else {
                continue
            }
            guard plasma.state == .alive else {
                continue
            }
            guard plasma.team != shooter.team else {
                continue
            }
            
            // efficient pass to rule out most targets
            guard abs(plasma.positionX - shooter.positionX) < myRange else {
                continue
            }
            guard abs(plasma.positionY - shooter.positionY) < myRange else {
                continue
            }
            
            let targetRange = sqrt((plasma.positionX - shooter.positionX) * (plasma.positionX - shooter.positionX) + (plasma.positionY - shooter.positionY) * (plasma.positionY - shooter.positionY))
            
            guard targetRange < myRange else {
                continue
            }
            
            var plasmaDirection = atan2(-1 * (plasma.positionY - shooter.positionY), plasma.positionX - shooter.positionX)
            if plasmaDirection < 0 {
                plasmaDirection = plasmaDirection + Double.pi * 2
            }
            
            let plasmaHalfArc = Laser.zapPlasma / targetRange  // radians
            logger.trace("Laser arc \(plasmaHalfArc) targetRange \(targetRange)")
            // 3 cases, 2 of which deal with origin
            if abs(plasmaDirection - self.direction) < plasmaHalfArc || (plasmaDirection - 0) + (Double.pi * 2 - self.direction) < plasmaHalfArc || (Double.pi * 2 - plasmaDirection) + (self.direction) < plasmaHalfArc {
                // arc is correct, may hit
                if targetRange < closestPlasmaRange {
                    // closest hit
                    closestPlasmaRange = targetRange
                    closestPlasmaHit = plasma
                }
            }
        }//for player in players

        if closestPlasmaRange < closestPlayerRange {
            closestPlayerHit = nil
        } else {
            closestPlasmaHit = nil
        }
        
        if let closestHit = closestPlayerHit {
            self.target = closestHit.slot
            self.status = .hit
            let damage = shooter.ship.laserDamage * (1.0 - closestPlayerRange / myRange)
            logger.trace("Laser myRange \(myRange) closestRange \(closestPlayerRange) damage \(damage)")
            closestHit.impact(damage: damage, attacker: self.player, whyDead: .laser)
            //let spMessage = MakePacket.spMessage(message: "Laser hit player \(closestHit.slot) for \(Int(damage)) damage", from: 255)
            shooter.sendMessage(message: "Laser hit player \(closestHit.slot) for \(Int(damage)) damage")
            //shooter.connection?.send(data: spMessage)
        } else if let closestPlasmaHit = closestPlasmaHit {
            self.target = closestPlasmaHit.number
            self.status = .hitPhoton
            self.targetPositionX = closestPlasmaHit.positionX
            self.targetPositionY = closestPlasmaHit.positionY
            closestPlasmaHit.explode()
            //let damage = shooter.ship.laserDamage * (1.0 - closestPlayerRange / myRange)
            //logger.trace("Laser myRange \(myRange) closestRange \(closestPlayerRange) damage \(damage)")
            //closestHit.impact(damage: damage, attacker: self.player, whyDead: .laser)
            //let spMessage = MakePacket.spMessage(message: "Laser hit player \(closestHit.slot) for \(Int(damage)) damage", from: 255)
            shooter.sendMessage(message: "Laser hit plasma \(closestPlasmaHit.number)")
        } else {
            self.status = .miss
            self.targetPositionX = self.positionX + cos(direction) * myRange
            self.targetPositionY = self.positionY - sin(direction) * myRange
            shooter.sendMessage(message: "Laser missed")
            //let spMessage = MakePacket.spMessage(message: "Laser missed", from: 255)
            //shooter.connection?.send(data: spMessage)
        }
        let spLaser = MakePacket.spLaser(laser: self)
        for player in universe.players.filter( { $0.status == .alive || $0.status == .explode }) {
            player.sendData(spLaser)
            /*if let context = player.context {
                context.eventLoop.execute {
                    let buffer = context.channel.allocator.buffer(bytes: spLaser)
                    _ = context.channel.write(buffer)
                }
            }*/
            //player.connection?.send(data: spLaser)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + shooter.ship.laserRecharge) {
            self.status = .free
            let spLaser = MakePacket.spLaser(laser: self)
            for player in universe.players.filter( { $0.status == .alive || $0.status == .explode }) {
                player.sendData(spLaser)
                /*if let context = player.context {
                    context.eventLoop.execute {
                        let buffer = context.channel.allocator.buffer(bytes: spLaser)
                        _ = context.channel.write(buffer)
                    }
                }*/
                //player.connection?.send(data: spLaser)
            }
        }
        
    }// func fire
}
