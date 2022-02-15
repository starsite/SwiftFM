//
//  FMLayouts.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Get Layouts -> .layouts

public struct FMLayouts: Codable {
    
    struct Result: Codable {
        let response: Response
        let messages: [Message]
    }
    
    struct Message: Codable {
        let code: String
        let message: String
    }
    
    struct Response: Codable {
        let layouts: [Layout]
    }
    
    struct Layout: Codable {
        let name: String
        let table: String?
        let isFolder: Bool?
        let folderLayoutNames: [FolderLayoutName]?
    }
    
    struct FolderLayoutName: Codable {
        let name: String
        let table: String
    }
    
}
