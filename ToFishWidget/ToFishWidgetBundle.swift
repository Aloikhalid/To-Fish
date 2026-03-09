//
//  ToFishWidgetBundle.swift
//  ToFishWidget
//
//  Created by alya Alabdulrahim on 21/09/1447 AH.
//

import WidgetKit
import SwiftUI

@main
struct ToFishWidgetBundle: WidgetBundle {
    var body: some Widget {
        AquariumWidget()
        ToFishWidgetControl()
        ToFishWidgetLiveActivity()
    }
}
