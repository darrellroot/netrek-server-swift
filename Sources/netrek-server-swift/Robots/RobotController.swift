//
//  RobotController.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/15/20.
//

import Foundation

class RobotController {
    
    let targetPlayersPerTeam = 4
    var robotId = 0
    
    init() {
    }
    
    func secondTimerFired() {
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
            if player.robot != nil {
                robots[player.team]! += 1
            }
        }
        for team in [Team.federation,Team.roman,Team.kazari,Team.orion] {
            if humans[team]! + robots[team]! < targetPlayersPerTeam {
                addRobot(team: team)
            }
        }
        //TODO delete extra robots
        for team in [Team.federation,Team.roman,Team.kazari,Team.orion] {
            if humans[team]! + robots[team]! > targetPlayersPerTeam && robots[team]! > 0 {
                deleteRobot(team: team)
            }
        }
    }
    func deleteRobot(team: Team) {
        guard let robotToDelete = universe.players.first(where: {$0.status != .free && $0.robot != nil && $0.team == team}) else {
            debugPrint("\(#file) \(#function) Error: Unable to find \(team) robot to delete")
            return
        }
        robotToDelete.disconnected()
    }
    func addRobot(team: Team) {
        self.robotId += 1
        guard let freeSlot = universe.players.first(where: {$0.status == .free}) else {
            debugPrint("\(#file) \(#function) Unable to find free slot")
            return
        }
        let newRobot = RobotModel1(player: freeSlot,universe: universe) as Robot
        
        freeSlot.robotConnected(robot: newRobot)
        
        freeSlot.receivedCpLogin(name: "Robot\(self.robotId)", password: "", userinfo: newRobot.userinfo)
        
        //moved to robot logic
        guard freeSlot.receivedCpOutfit(team: team, ship: newRobot.preferredShip) else {
            debugPrint("\(#file) \(#function) Unable to outfit ship")
            return
        }
        
    }
    
}
