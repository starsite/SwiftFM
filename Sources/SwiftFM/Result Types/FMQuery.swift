//
//  FMQuery.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Find Requests or Get RecordId -> .data?

public struct FMQuery {
    
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
        public let data: [Record]?  // <-- ✨ SwiftFM.query() method return
    }
    
    public struct DataInfo: Codable {
        public let database: String
        public let layout: String
        public let table: String
        public let totalRecordCount: Int
        public let foundCount: Int
        public let returnedCount: Int
    }
    
    public struct Record: Codable {
       public let recordId: String  // <-- ✨ useful as a \.keyPath in SwiftUI List views... ie. List(artists, id: \.recordId)
       public let modId: String
       public let fieldData: FieldData
       public let portalDataInfo: [PortalDataInfo]?
       public let portalData: PortalData
    }
    
    
    
    // 👇 these are your Swift model property names. Map your Filemaker field names with CodingKey string literals.
    
    public struct FieldData: Codable {
//        public let myProperty: String
//        // public let address: String
//        // ...
//
//        public enum CodingKeys: String, CodingKey {
//            case myProperty
//            // case name = "street_address"
//            // ...
//        }
    }
    
    
    
    public struct PortalDataInfo: Codable {
        public let portalObjectName: String
        public let database: String
        public let table: String
        public let foundCount: Int
        public let returnedCount: Int
    }
    
    /*
     ⚠️ defining Codable portal models is -possible- but kind of a PITA, to be honest. I just fire a second query() on the portal base table instead. Way more direct, and easier, IMO. Anyhoo, I'm including a Codable portal example below, so you can see the structure. Use them if you want.
    */
    
    
    // change `myPortalObjectName` and add your properties to `PortalRecord`.
    
    public struct PortalData: Codable {
        public let myPortalObjectName: [PortalRecord]?
    }
    
    
    // these are your Swift model property names. Map your Filemaker portal field names with CodingKey string literals.
    
    public struct PortalRecord: Codable {
        public let recordId: String
        public let modId: String
        // let myProperty: String
        // ...
        
        public enum CodingKeys: String, CodingKey {
            case recordId
            case modId
            // case myProperty = "relatedTable::fieldName"
            // ...
        }
        
    }
    
}
