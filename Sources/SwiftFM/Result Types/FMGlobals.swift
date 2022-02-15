//
//  FMGlobals.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Set Globals -> Bool

public struct FMGlobals: Codable {
    
    public struct Result: Codable {
        let response: Response
        let messages: [Message]
    }
    
    public struct Message: Codable {
        let code: String
        let message: String
    }
    
    public struct Response: Codable {
    }
}
