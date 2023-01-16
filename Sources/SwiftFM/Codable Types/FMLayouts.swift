//
//  FMLayouts.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/14/22.
//

import Foundation


// MARK: - Get Layouts -> .layouts

public struct FMLayouts: Codable {
    
    public let response: Response
    public let messages: [Message]
    
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
        
        public static func < (lhs: Layout, rhs: Layout) -> Bool {
            lhs.name < rhs.name
        }
    }
    
    public struct FolderLayoutName: Codable, Comparable {
        public let name: String
        public let table: String
        
        public static func < (lhs: FolderLayoutName, rhs: FolderLayoutName) -> Bool {
            lhs.name < rhs.name
        }
    }

}
