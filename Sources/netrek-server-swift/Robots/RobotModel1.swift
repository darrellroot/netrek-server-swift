//
//  RobotModel1.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/15/20.
//

import Foundation

class RobotModel1: Robot {
    
    enum Strategy: String {
        case refuel
        case repair
        case dogfight
    }
    
    var strategy: Strategy = .dogfight {
        didSet {
            if strategy != oldValue, let me = me, let user = me.user {
                for player in universe.humanPlayers.filter({$0.team == me.team}) {
                    player.sendMessage(message: "\(me.team.letter)\(me.slot.hex) \(user.name) I need to \(self.strategy.rawValue)")
                }
            }
        }
    }
    
    weak var me: Player?
    
    public let userinfo = "RobotMk2"
    public var preferredShip: ShipType {
        //cruiser twice as likely
        return [ShipType.scout,ShipType.destroyer,ShipType.cruiser,ShipType.cruiser,ShipType.battleship].randomElement()!
    }
    
    required init(player: Player, universe: Universe) {
        self.me = player
    }
    
    public func secondTimerFired() {
        guard let me = me else {
            return
        }
        switch me.status {
            
        case .free, .observe:
            //should not get here
            break
        case .outfit:
            guard me.receivedCpOutfit(team: me.team, ship: self.preferredShip) else {
                debugPrint("\(#file) \(#function) Unable to outfit ship")
                return
            }
            return
        case .explode:
            break
        case .dead:
            guard me.receivedCpOutfit(team: me.team, ship: self.preferredShip) else {
                debugPrint("\(#file) \(#function) Unable to outfit ship")
                return
            }
            return
        case .alive:
            decideStrategy()
            guard let nearestEnemy = self.nearestEnemy() else {
                return
            }
            adjustShields(nearestEnemy: nearestEnemy)
            shootLaser(nearestEnemy: nearestEnemy)
            shootTorpedo(nearestEnemy: nearestEnemy)
            switch self.strategy {
            case .refuel:
                strategyRefuel()
            case .repair:
                strategyRepair()
            case .dogfight:
                strategyDogfight(nearestEnemy: nearestEnemy)
            }
        }
    }
    private func adjustShields(nearestEnemy: Player) {
        guard let me = me else {
            return
        }
        let enemyDistance = NetrekMath.distance(me,nearestEnemy)
        if enemyDistance < Laser.baseRange * 2 {
            //shields should be up
            if !me.shieldsUp {
                me.receivedCpShield(up: true)
            }
        } else {
            if me.shieldsUp {
                me.receivedCpShield(up: false)
                if me.orbit != nil && self.strategy == .repair {
                    me.receivedRepair(true)
                }
            }
        }
    }
    private func shootLaser(nearestEnemy: Player) {
        guard let me = me else {
            return
        }
        let enemyDistance = NetrekMath.distance(me,nearestEnemy)
        if enemyDistance < Laser.baseRange / 2 {
            let enemyDirectionRadian = NetrekMath.angle(origin: me, target: nearestEnemy)
            let enemyDirectionNetrek = NetrekMath.directionRadian2Netrek(enemyDirectionRadian)
            me.fireLaser(direction: enemyDirectionNetrek)
        }
    }
    private func predictLocation(enemy: Player,time: Double) -> Location {
        let positionX = enemy.positionX + enemy.speed * Globals.WARP1 * 10 * cos(enemy.direction)
        let positionY = enemy.positionY - enemy.speed * Globals.WARP1 * 10 * sin(enemy.direction)
        return Location(positionX: positionX, positionY: positionY)
    }
    private func shootTorpedo(nearestEnemy: Player) {
        guard let me = me else {
            return
        }
        let enemyDistance = NetrekMath.distance(me,nearestEnemy)
        let timeToTarget = enemyDistance / (Globals.WARP1 * 10 * Double(me.ship.torpSpeed))
        let predictedEnemyLocation = predictLocation(enemy: nearestEnemy,time: timeToTarget)
        let predictedDistance = NetrekMath.distance(me,predictedEnemyLocation)
        //TODO adjust to torpedo range
        if predictedDistance < Laser.baseRange * 1.5 {
            let predictedDirectionRadian = NetrekMath.angle(origin: me, target: predictedEnemyLocation)
            let variance = Double.random(in: -0.2 ..< 0.2)
            me.fireTorpedo(direction: predictedDirectionRadian + variance)
        }
    }
    private func strategyDogfight(nearestEnemy: Player) {
        guard let me = me else {
            return
        }
        let enemyDistance = NetrekMath.distance(me,nearestEnemy)

        //random course toward enemy
        var baseDirectionRadian = NetrekMath.angle(origin: me, target: nearestEnemy)
        let evasive: Double
        if enemyDistance < Laser.baseRange * 4 {
            evasive = Double.random(in: Double.pi * -0.3 ..< Double.pi * 0.3)
        } else {
            evasive = Double.random(in: Double.pi * -0.1 ..< Double.pi * 0.1)
        }
        let directionRadian = baseDirectionRadian + evasive
        me.receivedDirection(direction: directionRadian)
        //random speed
        var speed = Int(me.ship.maxSpeed / 2 - 1)
        speed += Int.random(in: -2..<2)
        me.receivedCpSpeed(speed: speed)
    }
    private func strategyRepair() {
        guard let me = me else {
            return
        }
        if let planet = me.orbit {
            if !me.repair {
                me.receivedRepair(true)
            }
            return
        }
        if let planet = self.nearestRepairPlanet() {
            me.receivedPlanetLock(planetID: planet.planetID)
            me.receivedCpSpeed(speed: Int(me.ship.maxSpeed / 2))
            return
        } else {
            //no friendly fuel planet so we stop to repair
            me.receivedRepair(true)
        }
    }
    
    private func strategyRefuel() {
        guard let me = me else {
            return
        }
        if let planet = me.orbit, planet.fuel {
            return
        }
        if let planet = me.planetLock, planet.fuel {
            return
        }
        if let planet = self.nearestFuelPlanet() {
            me.receivedPlanetLock(planetID: planet.planetID)
            me.receivedCpSpeed(speed: Int(me.ship.maxSpeed / 2))
            return
        } else {
            //no friendly fuel planet so we stop to refuel
            me.receivedCpSpeed(speed: 0)
        }
    }
    
    private func decideStrategy() {
        guard let me = self.me else {
            debugPrint("\(#file) \(#function) Unable to identify myself")
            return
        }
        switch self.strategy {
            
        case .refuel:
            if me.fuel > (me.ship.maxFuel - 500) {
                self.strategy = .dogfight
            }
        case .repair:
            if me.damage < 10 {
                self.strategy = .dogfight
            }
        case .dogfight:
            if me.damage > me.ship.maxDamage / 2 {
                self.strategy = .repair
                return
            }
            if me.fuel < me.ship.maxFuel / 3 {
                self.strategy = .refuel
                return
            }
        }
    }
}
