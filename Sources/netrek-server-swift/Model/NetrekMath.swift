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
    static func distance(_ thing1: Thing,_ thing2: Thing) -> Double {
        return sqrt((thing1.positionX - thing2.positionX) * (thing1.positionX - thing2.positionX) + (thing1.positionY - thing2.positionY) * (thing1.positionY - thing2.positionY))
    }
    static func angle(origin: Thing, target: Thing) -> Double {
        //returns value in radians between 0 and 2*Pi
        var angle = atan2(-1 * (target.positionY - origin.positionY), target.positionX - origin.positionX)
        if angle < 0 {
            angle = angle + Double.pi * 2
        }
        return angle
    }
    static func angleDiff(_ angle1: Double, _ angle2: Double) -> Double {
        //returns diff between two angles, including dealing with 2*pi case
        // inputs must be between 0 and 2*Pi
        //TODO incorporate tests.  somewhat tested in default-mac-app
        var angle: Double
        switch angle2 - angle1 {
        case 0:
            angle = 0.0
        case 0 ..< Double.pi:
            angle = angle2 - angle1
        case -Double.pi ..< 0:
            angle = angle2 - angle1
        case Double.pi...:
            angle = -(Double.pi - (angle2 - (angle1 + Double.pi)))
        case ...(-Double.pi):
            angle = (Double.pi * 2 - angle1) + angle2
        default:
            // should not get here
            angle = 0.0
        }
        if angle <= -Double.pi {
            angle += 2 * Double.pi
        }
        if angle > Double.pi {
            angle -= Double.pi
        }
        return angle
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
