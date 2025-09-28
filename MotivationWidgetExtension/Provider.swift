//
//  Provider.swift
//  MotiVate
//
//  Created by Chris Venter on 20/5/2025.
//

import WidgetKit
import SwiftUI // For potential use, though not strictly necessary here
import Supabase // Required for RPC calls
import os // Import the os framework for Logger

// ImageResponse struct is now defined in MotiVate/core/SharedModels.swift
// Ensure SharedModels.swift is included in this widget extension's target membership.
 
struct Provider: TimelineProvider {
    // Create a logger instance for this provider.
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MotivationWidgetExtension", category: "Provider")

    // Explicit initializer to check if Provider is even being created
    init() {
        Self.logger.info("Provider initialized.")
    }

    // Provides a placeholder version of the widget.
    func placeholder(in context: Context) -> MotivationEntry {
        Self.logger.info("Placeholder requested. Family: \(context.family.description), isPreview: \(context.isPreview)")
        return MotivationEntry.staticWidgetPreview // Keep using static preview for gallery
    }

    // Provides a snapshot of the widget's content.
    func getSnapshot(in context: Context, completion: @escaping (MotivationEntry) -> Void) {
        Self.logger.info("Snapshot requested. Family: \(context.family.description), isPreview: \(context.isPreview)")
        if context.isPreview {
            Self.logger.info("Snapshot - isPreview is true, returning staticWidgetPreview.")
            completion(MotivationEntry.staticWidgetPreview)
            return
        }
        // For non-preview snapshot, immediately return the staticWidgetPreview.
        // getTimeline will be called shortly after to fetch the first real image.
        Self.logger.info("Snapshot - isPreview is false, returning staticWidgetPreview immediately.")
        completion(MotivationEntry.staticWidgetPreview)
    }

    // Provides an array of timeline entries.
    func getTimeline(in context: Context, completion: @escaping (Timeline<MotivationEntry>) -> Void) {
        Task {
            let currentEntry = await fetchMotivationEntry()
            // For this widget, we'll refresh according to the policy.
            // Let's set a refresh policy, e.g., 1 minute from now or .atEnd
            let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
            let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdateDate))
            // Log successful timeline creation
           // Self.logger.info("Timeline created. Entry date: \(currentEntry.date), ImageID: \(String(describing: currentEntry.imageId)), Has image data: \(currentEntry.imageData != nil), Error: \(currentEntry.errorMessage ?? "nil")")
            completion(timeline)
        }
    }

    private func fetchMotivationEntry() async -> MotivationEntry {
        Self.logger.info("Fetching motivation entry with offline fallback...")

        // Suppress App Group UserDefaults warning in SwiftUI preview or test context
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            Self.logger.warning("Running in SwiftUI preview context. Skipping App Group UserDefaults access.");
            return MotivationEntry.staticWidgetPreview
        }
        #endif
        
        let appGroupID = "group.myaccessibility.ai.motivate"
        let userDefaults = UserDefaults(suiteName: appGroupID)
        if userDefaults == nil {
            Self.logger.warning("App Group UserDefaults is nil. This may be a preview, test, or misconfigured context.")
        }
        
        let selectedCategoryIDsStrings = userDefaults?.stringArray(forKey: "selectedCategoryIDs") ?? []
        let categoryIDsForRPC: [Int64]? = selectedCategoryIDsStrings.isEmpty ? nil : selectedCategoryIDsStrings.compactMap { Int64($0) }

        Self.logger.debug("Selected category IDs for RPC: \(categoryIDsForRPC?.map { String($0) }.joined(separator: ", ") ?? "None (fully random)")")

        // Use the new getImageWithFallback method from SupabaseClient
        let (imageData, isFromOffline, imageId) = await SupabaseClient.shared.getImageWithFallback(categoryIds: categoryIDsForRPC)
        
        if let imageData = imageData {
            if isFromOffline {
                Self.logger.info("Successfully loaded offline image, size: \(imageData.count) bytes")
                return MotivationEntry(
                    date: Date(),
                    imageId: imageId,
                    imageURL: nil, // No URL for offline images
                    imageData: imageData,
                    isFromOffline: true
                )
            } else {
                Self.logger.info("Successfully loaded online image, ID: \(imageId ?? -1), size: \(imageData.count) bytes")
                return MotivationEntry(
                    date: Date(),
                    imageId: imageId,
                    imageURL: nil, // We have the data already
                    imageData: imageData,
                    isFromOffline: false
                )
            }
        } else {
            Self.logger.error("Failed to load any image (both online and offline failed)")
            let errorMessage = isFromOffline ? "No offline images available" : "Network error and no offline fallback"
            return MotivationEntry(date: Date(), imageId: nil, errorMessage: errorMessage)
        }
    }
} // Closing brace for struct Provider
