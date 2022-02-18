//
//  FMDatabases.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Get Databases -> .databases

public struct FMDatabases {
    
    public struct Result: Codable {
        public let response: Response
        public let messages: [Message]
    }
    
    public struct Message: Codable {
        public let code: String
        public let message: String
    }
    
    public struct Response: Codable {
        public let databases: [Database]
    }
    
    public struct Database: Codable, Comparable {
        public let name: String
        
        public static func < (lhs: FMDatabases.Database, rhs: FMDatabases.Database) -> Bool {
            lhs.name < rhs.name
        }
    }
}
