//
//  RobotController.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/15/20.
//

import Foundation

class RobotController {
    
    let targetPlayersPerTeam = 0
    var robotId = 0
    
    init() {
    }
    
    func checkBroncoRobotCount() {
        var humans: [Team:Int] = [:]
        var robots: [Team:Int] = [:]
                
        for team in Team.allCases {
            humans[team] = 0
            robots[team] = 0
        }
        for player in universe.players {
            if player.robot == nil && player.status != .free {
                humans[player.team]! += 1
            }
            if player.robot != nil && player.status != .free {
                robots[player.team]! += 1
            }
        }
        for team in Team.broncoTeams {
            if humans[team]! + robots[team]! < targetPlayersPerTeam {
                addRobot(team: team)
            }
        }
        //TODO delete extra robots
        for team in Team.broncoTeams {
            if humans[team]! + robots[team]! > targetPlayersPerTeam && robots[team]! > 0 {
                deleteRobot(team: team)
            }
        }
        
    }
    func checkEmpireRobotCount() {
        var humans = 0
        var robots = 0
        let targetPlayers = targetPlayersPerTeam * 4

        for player in universe.players {
            if player.robot == nil && player.status != .free {
                humans += 1
            }
            if player.robot != nil && player.status != .free {
                robots += 1
            }
        }
        if humans + robots < targetPlayers {
            addRobot()
        }
        if humans + robots > targetPlayers && robots > 0 {
            deleteRobot()
        }
    }
    func secondTimerFired() {
        switch netrekOptions.gameStyle {
            
        case .bronco:
            checkBroncoRobotCount()
        case .empire:
            checkEmpireRobotCount()
        }
    }
    
    // this is used in empire mode
    func deleteRobot() {
        let robotPlayers = universe.players.filter({$0.status != .free && $0.robot != nil})
        if let randomRobot = robotPlayers.randomElement() {
            randomRobot.disconnected()
        }
    }
    
    // this is used in bronco mode
    func deleteRobot(team: Team) {
        guard let robotToDelete = universe.players.first(where: {$0.status != .free && $0.robot != nil && $0.team == team}) else {
            logger.error("\(#file) \(#function) Error: Unable to find \(team) robot to delete")
            return
        }
        robotToDelete.disconnected()
    }
    
    // this is used in empire mode
    func addRobot() {
        self.robotId += 1
        let freeSlots = universe.players.filter({$0.status == .free})
        guard let freeSlot = freeSlots.randomElement() else {
            logger.error("\(#file) \(#function) Unable to find free slot")
            return
        }
        let newRobot = RobotModel1(player: freeSlot,universe: universe) as Robot
        
        let robotName = "\(newRobot.userinfo)-\(robotId)"
        freeSlot.robotConnected(robot: newRobot)
        
        //freeSlot.receivedCpLogin(name: robotName, password: "", userinfo: newRobot.userinfo)
        freeSlot.receivedCpLogin(name: robotName, robot: true, password: "", userinfo: newRobot.userinfo)
        let team = Team.federation //ignored in empire mode
        guard freeSlot.receivedCpOutfit(team: team, ship: newRobot.preferredShip) else {
            logger.error("\(#file) \(#function) Unable to outfit ship")
            return
        }

    }
    // this is used in bronco mode
    func addRobot(team: Team) {
        self.robotId += 1
        guard let freeSlot = universe.players.first(where: {$0.status == .free}) else {
            logger.error("\(#file) \(#function) Unable to find free slot")
            return
        }
        let newRobot = RobotModel1(player: freeSlot,universe: universe) as Robot
        
        let robotName = "\(newRobot.userinfo)-\(robotId)"
        freeSlot.robotConnected(robot: newRobot)
        
        freeSlot.receivedCpLogin(name: robotName, robot: true, password: "", userinfo: newRobot.userinfo)
        
        guard freeSlot.receivedCpOutfit(team: team, ship: newRobot.preferredShip) else {
            logger.error("\(#file) \(#function) Unable to outfit ship")
            return
        }
        
    }
    
}
