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

    enum CodingKeys: String, CodingKey {
        case version
        case saveToDatabase
        case name
        case password256Hash
        case userinfo
        case rank
        case tKills
        case tLosses
        case overallKills
        case overallLosses
        case tPlanets
        case tArmies
        case sbKills
        case sbLosses
        case intramuralArmies
        case intramuralPlanets
        case maxKills
        case sbMaxKills
        case tournamentTicks
    }
    // user names starting with "guest" should not be saved in permanent storage.  See player.receivedCpLogin()
    static var guestID = 1
    
    var version: Int = 2
    var saveToDatabase: Bool
    var needSpPlLogin = true
    var name: String {
        didSet {
            self.needSpPlLogin = true
        }
    }
    //var password: String // version 1
    var password256Hash: String // SHA256.description added version 2
    var userinfo: String {
        didSet {
            self.needSpPlLogin = true
        }
    }
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
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = 2
        saveToDatabase = try values.decode(Bool.self, forKey: .saveToDatabase)
        name = try values.decode(String.self, forKey: .name)
        password256Hash = try values.decode(String.self, forKey: .password256Hash)
        userinfo = try values.decode(String.self, forKey: .userinfo)
        rank = try values.decode(Rank.self, forKey: .rank)
        tKills = try values.decode(Int.self, forKey: .tKills)
        tLosses = try values.decode(Int.self, forKey: .tLosses)
        overallKills = try values.decode(Int.self, forKey: .overallKills)
        overallLosses = try values.decode(Int.self, forKey: .overallLosses)
        tPlanets = try values.decode(Int.self, forKey: .tPlanets)
        tArmies = try values.decode(Int.self, forKey: .tArmies)
        sbKills = try values.decode(Int.self, forKey: .sbKills)
        intramuralArmies = try values.decode(Int.self, forKey: .intramuralArmies)
        intramuralPlanets = try values.decode(Int.self, forKey: .intramuralPlanets)
        maxKills = try values.decode(Double.self, forKey: .maxKills)
        sbMaxKills = try values.decode(Double.self, forKey: .sbMaxKills)
        tournamentTicks = try values.decode(Int.self, forKey: .tournamentTicks)
        
    }

}
