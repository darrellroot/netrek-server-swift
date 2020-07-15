//
//  RobotModel1.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/15/20.
//

import Foundation

class RobotModel1: Robot {
    
    weak var player: Player?
    
    public let userinfo = "RobotModel1"
    public let preferredShip = ShipType.cruiser
    
    required init(player: Player, universe: Universe) {
        self.player = player
    }
    
    public func secondTimerFired() {
        
    }
    
}
