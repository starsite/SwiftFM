//
//  FMDatabases.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Get Databases -> .databases

public struct FMDatabases: Codable {
    
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
    
    public struct Database: Codable {
        public let name: String
    }
}
