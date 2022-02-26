//
//  FMResult.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Query, Get Record, or Get Records -> .dataInfo?

public struct FMResult {
    
    public struct Result: Codable {
        public let response: Response
        public let messages: [Message]
    }
    
    public struct Message: Codable {
        public let code: String
        public let message: String
    }
    
    public struct Response: Codable {
        public let dataInfo: DataInfo?
    }
    
    public struct DataInfo: Codable {
        public let database: String
        public let layout: String
        public let table: String
        public let totalRecordCount: Int
        public let foundCount: Int
        public let returnedCount: Int
    }
}
