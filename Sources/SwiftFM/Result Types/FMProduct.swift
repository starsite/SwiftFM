//
//  FMProduct.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Get Product Info -> .productInfo

public struct FMProduct: Codable {
    
    public struct Result: Codable {
        public let response: Response
        public let messages: [Message]
    }
    
    public struct Message: Codable {
        public let code: String
        public let message: String
    }
    
    public struct Response: Codable {
        public let productInfo: ProductInfo
    }
    
    public struct ProductInfo: Codable {
        public let name: String
        public let buildDate: String
        public let version: String
        public let dateFormat: String
        public let timeFormat: String
        public let timeStampFormat: String
    }
}
