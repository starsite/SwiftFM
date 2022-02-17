//
//  FMContainer.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Set Container -> fileName? - property on SwiftFM.setContainer()

public struct FMContainer {
    
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
