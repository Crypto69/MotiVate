//
//  ContentView.swift
//  MotiVate
//
//  Created by Chris Venter on 20/5/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var showingCategorySettings = false // To present settings modally or as a sheet

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading Motivation...")
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                        Button("Try Again") {
                            Task {
                                await viewModel.fetchMotivationalImage()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if let image = viewModel.motivationalImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        // Set a fixed frame size for the image as requested
                        .frame(width: 512, height: 512)
                        .padding() // Add some padding around the image
                } else {
                    Text("Tap refresh to get a motivational image.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Make VStack take available space
            .navigationTitle("MotiVate")
            .toolbar {
                // For macOS, toolbar items are typically placed without explicit navigationBarTrailing.
                // The system will place them in the main toolbar area.
                ToolbarItemGroup {
                    // Button to refresh the image
                    Button {
                        Task {
                            await viewModel.fetchMotivationalImage()
                        }
                    } label: {
                        Label("Refresh Image", systemImage: "arrow.clockwise")
                    }

                    // Button for Settings
                    Button {
                        showingCategorySettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingCategorySettings) {
                // Present CategorySettingsView as a sheet
                // Wrap in NavigationView if CategorySettingsView itself needs a title bar
                NavigationView {
                    CategorySettingsView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showingCategorySettings = false
                                    // Optionally, refresh image after settings change
                                    Task {
                                        await viewModel.fetchMotivationalImage()
                                    }
                                }
                            }
                        }
                }
                // For macOS, adjust sheet size for better readability of category descriptions
                .frame(minWidth: 540, idealWidth:540, maxWidth: 540, minHeight: 500, idealHeight: 600, maxHeight: 700)
            }
        }
    }
}

#Preview {
    ContentView()
}
