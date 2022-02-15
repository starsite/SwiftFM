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
        let response: Response
        let messages: [Message]
    }
    
    public struct Message: Codable {
        let code: String
        let message: String
    }
    
    public struct Response: Codable {
        let databases: [Database]
    }
    
    public struct Database: Codable {
        let name: String
    }
}
