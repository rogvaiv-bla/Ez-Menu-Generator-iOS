//
//  Item.swift
//  Ez Menu Generator
//
//  Created by eduard on 29/01/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
