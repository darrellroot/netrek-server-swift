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
        case tournamentTicks // seconds
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
    
    var tournamentTicks = 1  //start at 1 to avoid division by zero, measure in seconds
    
    var rawOffense: Double {
        return Double(tKills) / Double(tournamentTicks)
    }
    var rawBombing: Double {
        return Double(tArmies) / Double(tournamentTicks)
    }
    var rawPlanets: Double {
        return Double(tPlanets) / Double(tournamentTicks)
    }
    var offense: Double {
        return rawOffense / universe.userDatabase.cachedAverageOffense
    }
    var bombing: Double {
        return rawBombing / universe.userDatabase.cachedAverageBombing
    }
    var planets: Double {
        return rawPlanets / universe.userDatabase.cachedAveragePlanets
    }
    
    var DI: Double {
        return (offense + bombing + planets) * Double(tournamentTicks) / 3600.0
    }
    
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
    
    func considerPromotion() -> Bool {
        //returns true if promoted
        let DI = self.DI
        let rating = self.offense + self.bombing + self.planets
        switch self.rank {
        
        case .ensign:
            if DI >= 2.0 && rating >= 1 {
                self.rank = .lieutenant
                return true
            }
            if DI >= 4.0 && rating > 0 {
                self.rank = .lieutenant
                return true
            }
        case .lieutenant:
            if DI >= 8.0 && rating >= 2 {
                self.rank = .ltcmdr
                return true
            }
            if DI >= 16.0 && rating > 1 {
                self.rank = .ltcmdr
                return true
            }
            if DI >= 32.0 && rating > 0 {
                self.rank = .ltcmdr
                return true
            }
        case .ltcmdr:
            if DI >= 24.0 && rating >= 3 {
                self.rank = .commander
                return true
            }
            if DI >= 48.0 && rating > 2 {
                self.rank = .commander
                return true
            }
            if DI >= 96.0 && rating > 1 {
                self.rank = .commander
                return true
            }
        case .commander:
            if DI >= 60.0 && rating >= 4 {
                self.rank = .captain
                return true
            }
            if DI >= 120.0 && rating > 3 {
                self.rank = .captain
                return true
            }
            if DI >= 240.0 && rating > 2 {
                self.rank = .captain
                return true
            }
        case .captain:
            if DI >= 100.0 && rating >= 5 {
                self.rank = .fleetCaptain
                return true
            }
            if DI >= 200.0 && rating > 4 {
                self.rank = .fleetCaptain
                return true
            }
            if DI >= 400.0 && rating > 3 {
                self.rank = .fleetCaptain
                return true
            }

        case .fleetCaptain:
            if DI >= 150.0 && rating >= 6 {
                self.rank = .fleetCaptain
                return true
            }
            if DI >= 300.0 && rating > 5 {
                self.rank = .fleetCaptain
                return true
            }
            if DI >= 600.0 && rating > 4 {
                self.rank = .fleetCaptain
                return true
            }

        case .commodore:
            if DI >= 210.0 && rating >= 7 {
                self.rank = .fleetCaptain
                return true
            }
            if DI >= 420.0 && rating > 6 {
                self.rank = .fleetCaptain
                return true
            }
            if DI >= 840.0 && rating > 5 {
                self.rank = .fleetCaptain
                return true
            }

        case .rearAdmiral:
            if DI >= 320.0 && rating >= 8 {
                self.rank = .fleetCaptain
                return true
            }
            if DI >= 640.0 && rating > 7 {
                self.rank = .fleetCaptain
                return true
            }
            if DI >= 1280.0 && rating > 6 {
                self.rank = .fleetCaptain
                return true
            }

        case .admiral:
            break
        }
        return false
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
