//
//  MotivationWidgetExtensionBundle.swift
//  MotivationWidgetExtension
//
//  Created by Chris Venter on 20/5/2025.
//

import WidgetKit
import SwiftUI

// @main // Removed @main from here, as MotivationWidget struct (in MotivationWidgetExtension.swift) has the primary @main attribute.
struct MotivationWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        // Correctly reference the MotivationWidget struct, which is the actual widget.
        MotivationWidget()
    }
}
