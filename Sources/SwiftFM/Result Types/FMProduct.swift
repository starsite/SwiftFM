//
//  FMProduct.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Get Product Info -> .productInfo

public struct FMProduct: Codable {
    
    struct Result: Codable {
        let response: Response
        let messages: [Message]
    }
    
    struct Message: Codable {
        let code: String
        let message: String
    }
    
    struct Response: Codable {
        let productInfo: ProductInfo
    }
    
    struct ProductInfo: Codable {
        let name: String
        let buildDate: String
        let version: String
        let dateFormat: String
        let timeFormat: String
        let timeStampFormat: String
    }
}
