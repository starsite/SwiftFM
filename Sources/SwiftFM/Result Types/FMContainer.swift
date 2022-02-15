//
//  FMContainer.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Set Container -> fileName? (class property on SwiftFM.setContainer)

struct FMContainer: Codable {
    
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
