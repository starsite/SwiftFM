//
//  FMLayoutMetaData.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Get Layout Metadata -> .response

struct FMLayoutMetaData: Codable {
    
    struct Result: Codable {
        let response: Response
        let messages: [Message]
    }
    
    struct Message: Codable {
        let code: String
        let message: String
    }
    
    struct Response: Codable {
        let fieldMetaData: [Field]?
        let portalMetaData: PortalMetaData?
        let valueLists: [ValueList]?
    }
    
    struct Field: Codable {
        let name: String
        let type: String
        let displayType: String
        let result: String
        let global: Bool
        let autoEnter: Bool
        let fourDigitYear: Bool
        let maxRepeat: Int
        let maxCharacters: Int
        let notEmpty: Bool
        let numeric: Bool
        let timeOfDay: Bool
        let repetitionStart: Int
        let repetitionEnd: Int
        let valueList: String?
    }
    
    struct PortalMetaData: Codable {  // to do
    }
    
    struct ValueList: Codable {
        let name: String
        let type: String
        let values: [Value]
    }
    
    struct Value: Codable {
        let displayValue: String
        let value: String
    }
    
}
