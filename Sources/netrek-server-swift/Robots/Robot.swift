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
    init(player: Player, universe: Universe)
    
    func secondTimerFired()
}
