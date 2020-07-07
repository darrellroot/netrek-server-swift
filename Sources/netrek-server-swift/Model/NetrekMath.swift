//
//  NetrekMath.swift
//  NetrekServer
//
//  Created by Darrell Root on 6/30/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import Foundation

class NetrekMath {
    
    //netrek direction 0 is straight up
    //netrek direction 64 is straight right
    
    static func directionRadian2Netrek(_ direction: Double) -> UInt8 {
        let value = Int(64.0 - 128.0 * direction / Double.pi)
        if value < 0 {
            return UInt8(value + 256)
        } else {
            return UInt8(value)
        }
    }
    static func directionNetrek2Radian(_ directionNetrek: UInt8) -> Double {
        let answer = Double.pi * ((Double(directionNetrek) / -128.0) + 0.5)
        if answer > 0 {
            return answer
        } else {
            return answer + 2.0 * Double.pi
        }
    }
    static func directionNetrek2Radian(_ directionNetrek: Int) -> Double {
        var error = false
        var directionNetrek = directionNetrek
        while directionNetrek > 255 {
            if error == false {
                debugPrint("\(#file) \(#function) error directioNetrek \(directionNetrek)")
                error = true
            }
            directionNetrek = directionNetrek - 256
        }
        while directionNetrek < 0 {
            directionNetrek = directionNetrek + 256
            if error == false {
                debugPrint("\(#file) \(#function) error directioNetrek \(directionNetrek)")
                error = true
            }
        }
        let answer = Double.pi * ((Double(directionNetrek) / -128.0) + 0.5)
        if answer > 0 {
            return answer
        } else {
            return answer + 2.0 * Double.pi
        }
    }

}
