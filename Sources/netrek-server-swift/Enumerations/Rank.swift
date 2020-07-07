//
//  Rank.swift
//  NetrekServer
//
//  Created by Darrell Root on 6/24/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
// 

import Foundation

enum Rank {
    case ensign
    case lieutenant
    case ltcmdr
    case commander
    case captain
    case fleetCaptain
    case commodore
    case rearAdmiral
    case admiral
    
    var value: Int {
        switch self {
            
        case .ensign:
            return 0
        case .lieutenant:
            return 1
        case .ltcmdr:
            return 2
        case .commander:
            return 3
        case .captain:
            return 4
        case .fleetCaptain:
            return 5
        case .commodore:
            return 6
        case .rearAdmiral:
            return 7
        case .admiral:
            return 8
        }
    }
}
