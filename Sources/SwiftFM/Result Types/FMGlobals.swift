//
//  FMGlobals.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Set Globals -> Bool

struct FMGlobals: Codable {
    
    struct Result: Codable {
        let response: Response
        let messages: [Message]
    }
    
    struct Message: Codable {
        let code: String
        let message: String
    }
    
    struct Response: Codable {
    }
}
