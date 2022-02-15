//
//  DataExtension.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Data extension for SwiftFM.setContainer()

// if you have trouble sniffing correct mime types (or simply don't want to), uncomment the `mimeType = "application/octet-stream"` line in SwiftFM.setContainer()

public extension Data {
    
    mutating func append(_ string: String) {
        
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
    
    private static let types: [UInt8 : String] = [
        
        0xFF : "image/jpeg",
        0x89 : "image/png",
        0x47 : "image/gif",
        0x49 : "image/tiff",
        0x4D : "image/tiff",
        0x25 : "application/pdf",
        0xD0 : "application/vnd",
        0x46 : "text/plain"
    ]
    
    var mimeType: String {
        
        var c: UInt8 = 0
        copyBytes(to: &c, count: 1)
        
        return Data.types[c] ?? "application/octet-stream"
    }
}
