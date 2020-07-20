//
//  UserDatabase.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/20/20.
//

import Foundation

enum AuthenticationResult {
    case success(User)
    case failure
    case newUser(User)
}
class UserDatabase {
    
    var users: [User] = []
    let filename = "netrek.database"
    let fileManager = FileManager()

    public func authenticate(name: String, password: String, userinfo: String) -> AuthenticationResult {
        guard let existingUser = users.first(where: {$0.name == name}) else {
            //create new user
            let newUser = User(name: name, password: password, userinfo: userinfo)
            self.users.append(newUser)
            logger.info("Authentication created new user \(name) in user database")
            try? self.save()
            return .newUser(newUser)
        }
        // existing user check authentication
        guard password == existingUser.password else {
            logger.info("Authentication failed for user \(name)")
            return .failure
        }
        logger.info("Authentication succeeded for user \(name)")
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
        try! self.save()
    }
    
    public func save() throws {
        print("saving data")
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
