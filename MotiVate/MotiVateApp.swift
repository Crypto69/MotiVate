//
//  MotiVateApp.swift
//  MotiVate
//
//  Created by Chris Venter on 20/5/2025.
//

import SwiftUI

@main
struct MotiVateApp: App {
    var body: some Scene {
        // Using Window instead of WindowGroup to ensure only one instance of the main window.
        // Provide a title for the window, e.g., "MotiVate".
        // Provide a unique ID for the window. This is required for `Window`.
        Window("MotiVate", id: "main") {
            ContentView()
        }
        // Ensure the window can be closed and reopened correctly.
        // For macOS, it's also common to handle app termination when the last window is closed,
        // or to keep the app running. The default behavior with `Window` should be suitable here.
    }
}
