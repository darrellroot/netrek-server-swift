//
//  Robot.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/15/20.
//

import Foundation

protocol Robot {
    var userinfo: String { get }
    var preferredShip: ShipType { get }
    var me: Player? { get }
    init(player: Player, universe: Universe)
    
    func secondTimerFired()
}

extension Robot {
    func nearestFuelPlanet() -> Planet? {
        guard let me = me else {
            return nil
        }
        var nearestPlanet: Planet? = nil
        var nearestDistance = Globals.GalaxyWidth * 2
        for candidatePlanet in universe.planets.filter({$0.team == me.team && $0.fuel}) {
            if let _ = nearestPlanet {
                let candidateDistance = NetrekMath.distance(candidatePlanet, me)
                if candidateDistance < nearestDistance {
                    nearestDistance = candidateDistance
                    nearestPlanet = candidatePlanet
                }
            } else {
                //first fuel planet in our algorithm
                nearestPlanet = candidatePlanet
            }
        }
        return nearestPlanet
    }
    func nearestRepairPlanet() -> Planet? {
        guard let me = me else {
            return nil
        }
        var nearestPlanet: Planet? = nil
        var nearestDistance = Globals.GalaxyWidth * 2
        for candidatePlanet in universe.planets.filter({$0.team == me.team && $0.repair}) {
            if let _ = nearestPlanet {
                let candidateDistance = NetrekMath.distance(candidatePlanet, me)
                if candidateDistance < nearestDistance {
                    nearestDistance = candidateDistance
                    nearestPlanet = candidatePlanet
                }
            } else {
                //first fuel planet in our algorithm
                nearestPlanet = candidatePlanet
            }
        }
        return nearestPlanet
    }
    func nearestEnemy() -> Player? {
        guard let me = me else {
            return nil
        }
        var nearestEnemy: Player? = nil
        var nearestDistance = Globals.GalaxyWidth * 2
        for candidateEnemy in universe.players.filter({$0.status == .alive && $0.team != me.team}) {
            if let _ = nearestEnemy {
                let candidateDistance = NetrekMath.distance(candidateEnemy, me)
                if candidateDistance < nearestDistance {
                    nearestDistance = candidateDistance
                    nearestEnemy = candidateEnemy
                }
            } else {
                //first enemy in our algorithm
                nearestEnemy = candidateEnemy
            }
        }
        return nearestEnemy
    }

}
