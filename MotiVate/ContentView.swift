//  ContentView.swift
//  MotiVate
//
//  Created by Chris Venter on 20/5/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @EnvironmentObject var appMenuState: AppMenuState

    var body: some View {
        NavigationSplitView {
            // Primary content area (sidebar)
            VStack {
                // Header row: logo, title, subtitle, About button on the right
                HStack(alignment: .top, spacing: 16) {
                    // App logo and title/subtitle
                    HStack(alignment: .center, spacing: 12) {
                        Image("AppLogo")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("MotiVate")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Daily reminders of strength, hope, and purpose—one image at a time.")
                                .font(.subheadline)
                                .italic()
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)

                    Spacer()

                    // About button and version on the right
                    VStack(alignment: .trailing, spacing: 2) {
                        Button {
                            appMenuState.showAbout = true
                        } label: {
                            Label("About", systemImage: "info.circle")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal)

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
                        .frame(width: 512, height: 512)
                        .padding()
                } else {
                    Text("Tap refresh to get a motivational image.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("MotiVate")
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        Task {
                            await viewModel.fetchMotivationalImage()
                        }
                    } label: {
                        Label("Refresh Image", systemImage: "arrow.clockwise")
                    }
                }
            }
        } detail: {
            CategorySettingsView()
                .frame(minWidth: 500, idealWidth: 550, minHeight: 500, idealHeight: 800)
                .navigationTitle("Settings")
        }
        .sheet(isPresented: $appMenuState.showAbout) {
            AboutView()
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
}
