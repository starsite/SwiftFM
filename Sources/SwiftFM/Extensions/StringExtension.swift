//
//  StringExtension.swift
//  SwiftFM
//
//  Created by Brian Hamm on 2/17/22.
//

import Foundation


// MARK: - String extension for SwiftFM.getRecords()

public extension String {
    
    var urlEncoded: String? {
        
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
    }
}

