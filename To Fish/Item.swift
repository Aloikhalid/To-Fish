//
//  Item.swift
//  To Fish
//
//  Created by alya Alabdulrahim on 10/09/1447 AH.
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
