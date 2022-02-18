//
//  FMLayouts.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Get Layouts -> .layouts

public struct FMLayouts {
    
    public struct Result: Codable {
        public let response: Response
        public let messages: [Message]
    }
    
    public struct Message: Codable {
        public let code: String
        public let message: String
    }
    
    public struct Response: Codable {
        public let layouts: [Layout]
    }
    
    public struct Layout: Codable, Comparable {
        public let name: String
        public let table: String?
        public let isFolder: Bool?
        public let folderLayoutNames: [FolderLayoutName]?
        
        public static func < (lhs: FMLayouts.Layout, rhs: FMLayouts.Layout) -> Bool {
            lhs.name < rhs.name
        }
    }
    
    public struct FolderLayoutName: Codable, Comparable {
        public let name: String
        public let table: String
        
        public static func < (lhs: FMLayouts.FolderLayoutName, rhs: FMLayouts.FolderLayoutName) -> Bool {
            lhs.name < rhs.name
        }
    }
    
}
