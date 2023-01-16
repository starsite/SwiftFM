//
//  FMRecord.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Create Record, Duplicate Record, or Edit Record -> .recordId? or .modId?
    
public struct FMRecord: Codable {
    
    public let response: Response
    public let messages: [Message]
    
    public struct Message: Codable {
        public let code: String
        public let message: String
    }
    
    public struct Response: Codable {
        public let recordId: String?
        public let modId: String?
    }

}
