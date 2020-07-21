//
//  User.swift
//  NetrekServer
//
//  Created by Darrell Root on 6/23/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
// 

import Foundation
import Crypto

class User: Codable {

    // user names starting with "guest" should not be saved in permanent storage.  See player.receivedCpLogin()
    static var guestID = 1
    
    var version: Int = 2
    var saveToDatabase: Bool
    var name: String
    //var password: String // version 1
    var password256Hash: String // SHA256.description added version 2
    var userinfo: String
    var rank: Rank = .ensign
    
    //the entries below are long-term stats
    var tKills = 0
    var tLosses = 0
    var overallKills = 0
    var overallLosses = 0
    var tPlanets = 0
    var tArmies = 0
    var sbKills = 0
    var sbLosses = 0
    var intramuralArmies = 0
    var intramuralPlanets = 0
    var maxKills = 0.0
    var sbMaxKills = 0.0
    
    var tournamentTicks = 1  //start at 1 to avoid division by zero
    
    init(name: String, password256Hash: String, userinfo: String) {
        self.name = name
        self.saveToDatabase = true
        self.password256Hash = password256Hash
        self.userinfo = userinfo
    
    }
    init(name: String, saveToDatabase: Bool, userinfo: String) {
        self.name = name
        self.saveToDatabase = false
        self.password256Hash = ""
        self.userinfo = userinfo
    }
}
