//
//  ShipType.swift
//  Netrek2
//
//  Created by Darrell Root on 5/5/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
// 

import Foundation

enum ShipType: Int, CaseIterable {
    case scout = 0
    case destroyer = 1
    case cruiser = 2
    case battleship = 3
    case assault = 4
    case starbase = 5
    //case battlecruiser = 6
    //case att = 7
    var description: String {
        switch self {
            
        case .scout:
            return "SC"
        case .destroyer:
            return "DD"
        case .cruiser:
            return "CA"
        case .battleship:
            return "BB"
        case .assault:
            return "AS"
        case .starbase:
            return "SB"
        //case .battlecruiser:
        //    return "BC"
        }
    }
    var maxShield: Double {
        switch self {
            
        case .scout:
            return 75
        case .destroyer:
            return 85
        case .cruiser:
            return 100
        case .battleship:
            return 130
        case .assault:
            return 80
        case .starbase:
            return 500
        }
    }
    var turnSpeed: Double {
        // direction change in radians per 0.1sec tick = turnSpeed / ( speed * speed)
        switch self {
            
        case .scout:
            return 570 * Double.pi * 2 / 256
        case .destroyer:
            return 310 * Double.pi * 2 / 256
        case .cruiser:
            return 170 * Double.pi * 2 / 256
        case .battleship:
            return 75 * Double.pi * 2 / 256
        case .assault:
            return 120 * Double.pi * 2 / 256
        case .starbase:
            return 50 * Double.pi * 2 / 256
        }
    }
    var acceleration: Double {
        //change in speed per second
        switch self {
            
        case .scout:
            return 2
        case .destroyer:
            return 2
        case .cruiser:
            return 1.5
        case .battleship:
            return 0.8
        case .assault:
            return 1
        case .starbase:
            return 1
        }
    }
    var maxSpeed: Double {
        switch self {
            
        case .scout:
            return 12.0
        case .destroyer:
            return 10.0
        case .cruiser:
            return 9.0
        case .battleship:
            return 8.0
        case .assault:
            return 8.0
        case .starbase:
            return 2.0
        }
    }
    var warpCost: Int {
        //fuel used per second per warp speed
        switch self {
            
        case .scout:
            return 20
        case .destroyer:
            return 30
        case .cruiser:
            return 40
        case .battleship:
            return 60
        case .assault:
            return 30
        case .starbase:
            return 100
        }
    }
    var recharge: Int {
        // fuel recharged per second
        // this must be larger than warpcost
        switch self {
            
        case .scout:
            return 160
        case .destroyer:
            return 220
        case .cruiser:
            return 240
        case .battleship:
            return 280
        case .assault:
            return 200
        case .starbase:
            return 700
        }
    }
    var detCost: Int {
        return 100
    }
    var shieldCost: Int {
        // shield cost per second
        switch self {
            
        case .scout, .destroyer, .cruiser, .battleship:
            return 20
        case .assault:
            return 30
        case .starbase:
            return 60
        }
    }
    var maxArmies: Int {
        switch self {
        case .scout:
            return 2
        case .destroyer:
            return 5
        case .cruiser:
            return 10
        case .battleship:
            return 6
        case .assault:
            return 20
        case .starbase:
            return 25
        }
    }
    var maxFuel: Int {
        switch self {
            
        case .scout:
            return 5000
        case .destroyer:
            return 7000
        case .cruiser:
            return 10000
        case .battleship:
            return 14000
        case .assault:
            return 6000
        case .starbase:
            return 60000
        }
    }
    var weaponCoolRate: Int { // per second
        switch self {
        case .scout:
            return 30
        case .destroyer:
            return 20
        case .cruiser:
            return 20
        case .battleship:
            return 30
        case .assault:
            return 20
        case .starbase:
            return 40
        }
    }
    var engineCoolRate: Double { // per second
        switch self {
        case .scout:
            return 80
        case .destroyer:
            return 70
        case .cruiser:
            return 60
        case .battleship:
            return 60
        case .assault:
            return 60
        case .starbase:
            return 40
        }
    }
    var tractorRange: Double {
        switch self {
        case .scout:
            return 0.7 * 6000
        case .destroyer:
            return 0.9 * 6000
        case .cruiser:
            return 6000
        case .battleship:
            return 1.2 * 6000
        case .assault:
            return 0.7 * 6000
        case .starbase:
            return 1.5 * 6000
        }
    }
    var tractorStrength: Double {
        switch self {
        case .scout:
            return 2000
        case .destroyer:
            return 2500
        case .cruiser:
            return 3000
        case .battleship:
            return 3700
        case .assault:
            return 2500
        case .starbase:
            return 8000
        }
    }
    var explosionDamage: Double {
        switch self {
            
        case .scout:
            return 75
        case .destroyer, .cruiser,.battleship, .assault:
            return 100
        case .starbase:
            return 200
        }
    }
    var explosionRange: Double {
        return 3000
    }
    var mass: Double {
        switch self {
        case .scout:
            return 1500
        case .destroyer:
            return 1800
        case .cruiser:
            return 2000
        case .battleship:
            return 2300
        case .assault:
            return 2300
        case .starbase:
            return 5000
        }
    }
    var torpSpeed: Int {
        switch self {
            
        case .scout:
            return 16
        case .destroyer:
            return 14
        case .cruiser:
            return 12
        case .battleship:
            return 12
        case .assault:
            return 16
        case .starbase:
            return 14
        }
    }
    var torpFuse: Double {
        let variation = Double.random(in: 0.0 ..< 2.0)
        switch self {
            
        case .scout:
            return 1.6 + variation
        case .destroyer:
            return 3.0 + variation
        case .cruiser:
            return 4.0 + variation
        case .battleship:
            return 4.0 + variation
        case .assault:
            return 3.0 + variation
        case .starbase:
            return 3.0 + variation
        }
    }
    
    var torpDamage: Double {
        switch self {
            
        case .scout:
            return 25
        case .destroyer:
            return 30
        case .cruiser:
            return 40
        case .battleship:
            return 40
        case .assault:
            return 30
        case .starbase:
            return 30
        }
    }
    var torpCost: Double {
        switch self {
            
        case .scout:
            return 7 * self.torpDamage
        case .destroyer:
            return 7 * self.torpDamage
        case .cruiser:
            return 7 * self.torpDamage
        case .battleship:
            return 9 * self.torpDamage
        case .assault:
            return 9 * self.torpDamage
        case .starbase:
            return 10 * self.torpDamage
        }
    }
    var plasmaDamage: Double {
        switch self {
        case .scout:
            return 1
        case .destroyer:
            return 75
        case .cruiser:
            return 100
        case .battleship:
            return 130
        case .assault:
            return 1
        case .starbase:
            return 150
        }
    }
    var plasmaCost: Double {
        switch self {
        case .scout:
            return 20 * self.plasmaDamage
        case .destroyer:
            return 30 * self.plasmaDamage
        case .cruiser:
            return 30 * self.plasmaDamage
        case .battleship:
            return 30 * self.plasmaDamage
        case .assault:
            return 20 * self.plasmaDamage
        case .starbase:
            return 25 * self.plasmaDamage
        }
    }
    var plasmaSpeed: Double {
        return 15
    }
    var plasmaFuse: Double {
        let variation = Double.random(in: 0.0 ..< 2.0)
        switch self {
            
        case .scout:
            return 1.6 + variation
        case .destroyer:
            return 3.0 + variation
        case .cruiser:
            return 3.3 + variation
        case .battleship:
            return 3.5 + variation
        case .assault:
            return 3.0 + variation
        case .starbase:
            return 2.5 + variation
        }
    }

    var cloakCost: Int {
        // cloak cost per second
        switch self {
            
        case .scout:
            return 170
        case .destroyer:
            return 210
        case .cruiser:
            return 260
        case .battleship:
            return 300
        case .assault:
            return 170
        case .starbase:
            return 750
        }
    }
    var maxDamage: Double {
        switch self {
            
        case .scout:
            return 75
        case .destroyer:
            return 85
        case .cruiser:
            return 100
        case .battleship:
            return 130
        case .assault:
            return 200
        case .starbase:
            return 600
        }
    }
    var repair: Double {
        // repair rate per second
        switch self {
            
        case .scout:
            return 0.8
        case .destroyer:
            return 1
        case .cruiser:
            return 1.12
        case .battleship:
            return 1.25
        case .assault:
            return 1.20
        case .starbase:
            return 1.40
        }
    }
    var laserRecharge: Double {
        switch self {
        case .scout, .destroyer, .cruiser, .battleship, .assault:
            return 1.0
        case .starbase:
            return 0.4
        }
    }
    var laserDamage: Double {
        switch self {
            
        case .scout:
            return 75
        case .destroyer:
            return 85
        case .cruiser:
            return 100
        case .battleship:
            return 120
        case .assault:
            return 80
        case .starbase:
            return 120
        }
    }
    var laserCost: Double {
        switch self {
            
        case .scout, .destroyer, .cruiser, .assault:
            return 7 * laserDamage
        case .battleship:
            return 10 * laserDamage
        case .starbase:
            return 8 * laserDamage
        }
    }
}
