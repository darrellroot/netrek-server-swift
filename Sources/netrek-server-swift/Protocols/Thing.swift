//
//  Thing.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/13/20.
//

import Foundation

protocol Thing {
    //space objects have position
    var positionX: Double { get }
    var positionY: Double { get }
}
