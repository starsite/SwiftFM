//
//  FMScripts.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/16/22.
//

import Foundation


// MARK: - Get Scripts -> .scripts
    
public struct FMScripts: Codable {
    
    public let response: Response
    public let messages: [Message]
    
    public struct Message: Codable {
        public let code: String
        public let message: String
    }
    
    public struct Response: Codable {
        public let scripts: [Script]
    }
    
    public struct Script: Codable, Comparable {
        public let name: String
        public let isFolder: Bool
        public let folderScriptNames: [FolderScriptName]?
        
        public static func < (lhs: Script, rhs: Script) -> Bool {
            lhs.name < rhs.name
        }
    }
    
    public struct FolderScriptName: Codable, Comparable {
        public let name: String
        public let isFolder: Bool
        
        public static func < (lhs: FolderScriptName, rhs: FolderScriptName) -> Bool {
            lhs.name < rhs.name
        }
    }

}
