//
//  FMLayoutMetaData.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Get Layout Metadata -> .response

public struct FMLayoutMetaData {
    
    public struct Result: Codable {
        public let response: Response
        public let messages: [Message]
    }
    
    public struct Message: Codable {
        public let code: String
        public let message: String
    }
    
    public struct Response: Codable {
        public let fieldMetaData: [Field]?
        public let portalMetaData: PortalMetaData?
        public let valueLists: [ValueList]?
    }
    
    public struct Field: Codable, Comparable {
        public let name: String
        public let type: String
        public let displayType: String
        public let result: String
        public let global: Bool
        public let autoEnter: Bool
        public let fourDigitYear: Bool
        public let maxRepeat: Int
        public let maxCharacters: Int
        public let notEmpty: Bool
        public let numeric: Bool
        public let timeOfDay: Bool
        public let repetitionStart: Int
        public let repetitionEnd: Int
        public let valueList: String?
        
        public static func < (lhs: FMLayoutMetaData.Field, rhs: FMLayoutMetaData.Field) -> Bool {
            lhs.name < rhs.name
        }
    }
    
    public struct PortalMetaData: Codable {  // to do
    }
    
    public struct ValueList: Codable, Comparable {
        public let name: String
        public let type: String
        public let values: [Value]
        
        public static func < (lhs: FMLayoutMetaData.ValueList, rhs: FMLayoutMetaData.ValueList) -> Bool {
            lhs.name < rhs.name
        }
    }
    
    public struct Value: Codable, Comparable {
        public let displayValue: String
        public let value: String
        
        public static func < (lhs: FMLayoutMetaData.Value, rhs: FMLayoutMetaData.Value) -> Bool {
            lhs.displayValue < rhs.displayValue
        }
    }
    
}
