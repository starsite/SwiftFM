//
//  FMGlobals.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Set Globals -> Bool

public struct FMGlobals {
    
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
