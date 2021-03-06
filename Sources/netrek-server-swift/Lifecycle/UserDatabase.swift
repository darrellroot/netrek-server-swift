//
//  UserDatabase.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/20/20.
//

import Foundation
import Crypto

enum AuthenticationResult {
    case success(User)
    case failure
    case newUser(User)
}
class UserDatabase {
    
    var users: [User] = []
    let filename = "netrek.database"
    let fileManager = FileManager()

    public func averageOffense() -> Double {
        guard users.count > 0 else {
            return 1.0
        }
        var totalOffense = 0.000001 // > 0 to prevent underflow
        for user in users {
            totalOffense += user.rawOffense
        }
        return totalOffense / Double(users.count)
    }
    
    public func averageBombing() -> Double {
        guard users.count > 0 else {
            return 1.0
        }
        var totalBombing = 0.000001 // > 0 to prevent underflow
        for user in users {
            totalBombing += user.rawBombing
        }
        return totalBombing / Double(users.count)
    }
    
    public func averagePlanets() -> Double {
        guard users.count > 0 else {
            return 1.0
        }
        var totalPlanets = 0.000001 // > 0 to prevent underflow
        for user in users {
            totalPlanets += user.rawPlanets
        }
        return totalPlanets / Double(users.count)
    }
    
    var cachedAverageOffense = 0.1
    var cachedAverageBombing = 0.1
    var cachedAveragePlanets = 0.1
    
    public func updateStats() {
        self.cachedAverageOffense = averageOffense()
        self.cachedAverageBombing = averageBombing()
        self.cachedAveragePlanets = averagePlanets()
    }
    
    public func authenticate(name: String, password: String, userinfo: String) -> AuthenticationResult {
        
        guard let passwordData = password.data(using: .utf8) else {
            logger.error("unable to SHA256 password for user \(name)")
            return .failure
        }
        let password256Hash = SHA256.hash(data: passwordData).description
        guard let existingUser = users.first(where: {$0.name == name}) else {
            //create new user
            
            let newUser = User(name: name, password256Hash: password256Hash, userinfo: userinfo)
            self.users.append(newUser)
            logger.info("Authentication created new user \(name) in user database")
            try? self.save()
            return .newUser(newUser)
        }
        // existing user check authentication
        guard password256Hash == existingUser.password256Hash else {
            logger.info("Authentication failed for user \(name)")
            return .failure
        }
        logger.info("Authentication succeeded for user \(name)")
        //update userinfo in database
        existingUser.userinfo = userinfo
        return .success(existingUser)
    }
    init() {
        var url = URL(fileURLWithPath: netrekOptions.directory)
        url.appendPathComponent(filename)
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            logger.critical("Unable to read user database from \(url) error \(error)")
            return
        }
        let decoder = JSONDecoder()
        do {
            let users = try decoder.decode([User].self, from: data)
            self.users = users
        } catch {
            logger.critical("Unable to decode user database from \(url) error \(error)")
            return
        }
        self.updateStats()
        try! self.save()
    }
    
    public func save() throws {
        print("saving user database")
        let encoder = JSONEncoder()
        
        let directory = netrekOptions.directory
        if !fileManager.directoryExists(directory) {
            do {
                try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: false)
            } catch {
                logger.critical("\(#file) \(#function) Unable to create directory \(directory) error \(error)")
                throw error
                //fatalError("\(#file) \(#function) Unable to create directory \(directory) error \(error)")
            }
        }
        var url = URL(fileURLWithPath: netrekOptions.directory)
        url.appendPathComponent(filename)

        if let encoded = try? encoder.encode(users)  {
            do {
                try encoded.write(to: url, options: .atomic)
            } catch {
                logger.critical("Unable to write user database to \(url)")
                throw error
                //fatalError("\(#file) \(#function) Unable to write user databsae to \(url)")
            }
        }
        logger.info("Saved user database to url \(url)")
    }
}
