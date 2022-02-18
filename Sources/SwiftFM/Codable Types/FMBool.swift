//
//  FMBool.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/16/22.
//

import Foundation


// MARK: - Set Container, Set Globals, Execute Script -> Bool

public struct FMBool {
    
    public struct Result: Codable {
        public let response: Response
        public let messages: [Message]
    }
    
    public struct Message: Codable {
        public let code: String
        public let message: String
    }
    
    public struct Response: Codable {
    }
}
