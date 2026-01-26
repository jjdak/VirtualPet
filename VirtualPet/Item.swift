//
//  Item.swift
//  VirtualPet
//
//  Created by 冯卓 on 2026/1/26.
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
