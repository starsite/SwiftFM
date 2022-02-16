//
//  DataInfo.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - DataInfo response for Find Requests and Get RecordId        

    public struct DataInfo: Codable {
        
        public let database: String
        public let layout: String
        public let table: String
        public let totalRecordCount: Int
        public let foundCount: Int
        public let returnedCount: Int
    }
