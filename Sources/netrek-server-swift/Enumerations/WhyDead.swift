//
//  Weapon.swift
//  NetrekServer
//
//  Created by Darrell Root on 7/3/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
// 

import Foundation
enum WhyDead: Int {
    // listing all the things that can cause damage
    // goes into the player.whyDead field
    case none = 0
    case quit = 1
    case torpedo = 2
    case laser = 3
    case planet = 4
    case explosion = 5
    case genocide = 9
    case plasma = 11
    case detTorp = 16
}
