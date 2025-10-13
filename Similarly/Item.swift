//
//  Item.swift
//  Similarly
//
//  Created by Tamer Savaşcı on 13.10.2025.
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
