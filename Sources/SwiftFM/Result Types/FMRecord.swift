//
//  FMRecord.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Create Record, Duplicate Record, or Edit Record -> .recordId? or .modId?

struct FMRecord: Codable {
    
    struct Result: Codable {
        let response: Response
        let messages: [Message]
    }
    
    struct Message: Codable {
        let code: String
        let message: String
    }
    
    struct Response: Codable {
        let recordId: String?
        let modId: String?
    }
}
