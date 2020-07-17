//
//  FileManager-extensions.swift
//  netrek-server-swift
//
//  Created by Darrell Root on 7/17/20.
//

import Foundation

//https://stackoverflow.com/questions/24696044/nsfilemanager-fileexistsatpathisdirectory-and-swift
extension FileManager {

    func directoryExists(_ atPath: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: atPath, isDirectory:&isDirectory)
        return exists && isDirectory.boolValue
    }
}
