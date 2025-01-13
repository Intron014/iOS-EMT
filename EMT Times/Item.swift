//
//  Item.swift
//  EMT Times
//
//  Created by Jorge Benjumea on 13/1/25.
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
