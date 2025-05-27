//
//  MotiVateApp.swift
//  MotiVate
//
//  Created by Chris Venter on 20/5/2025.
//

import SwiftUI

// App-wide menu state for About window
final class AppMenuState: ObservableObject {
    @Published var showAbout: Bool = false
}

@main
struct MotiVateApp: App {
    @StateObject private var appMenuState = AppMenuState()

    var body: some Scene {
        Window("MotiVate", id: "main") {
            ContentView()
                .environmentObject(appMenuState)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About MotiVate") {
                    appMenuState.showAbout = true
                }
            }
        }
    }
}
