//
//  FMLayoutMetaData.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Get Layout Metadata -> .response

public struct FMLayoutMetaData: Codable {
    
    public struct Result: Codable {
        let response: Response
        let messages: [Message]
    }
    
    public struct Message: Codable {
        let code: String
        let message: String
    }
    
    public struct Response: Codable {
        let fieldMetaData: [Field]?
        let portalMetaData: PortalMetaData?
        let valueLists: [ValueList]?
    }
    
    public struct Field: Codable {
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
    
    public struct PortalMetaData: Codable {  // to do
    }
    
    public struct ValueList: Codable {
        let name: String
        let type: String
        let values: [Value]
    }
    
    public struct Value: Codable {
        let displayValue: String
        let value: String
    }
    
}
