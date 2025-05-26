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
        //Self.logger.info("Timeline requested. Family: \(context.family.description), isPreview: \(context.isPreview). Will call fetchMotivationEntry.")
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
        Self.logger.info("Fetching motivation entry...")
        var downloadedImageData: Data? = nil
        
        let appGroupID = "group.ai.myaccessibility.motivate"
        let userDefaults = UserDefaults(suiteName: appGroupID)
        
        let selectedCategoryIDsStrings = userDefaults?.stringArray(forKey: "selectedCategoryIDs") ?? []
        let categoryIDsForRPC: [Int64]? = selectedCategoryIDsStrings.isEmpty ? nil : selectedCategoryIDsStrings.compactMap { Int64($0) }

        //Self.logger.debug("Selected category IDs for RPC: \(categoryIDsForRPC?.map { String($0) }.joined(separator: ", ") ?? "None (fully random)")")

        do {
            // Call the RPC function "get_random_image"
            // Assuming SupabaseClient.shared.client is the Supabase.SupabaseClient instance
            // The type ImageResponse should now resolve from the shared MotiVate/core/SharedModels.swift
            let imageResponse: ImageResponse = try await SupabaseClient.shared.client
                .rpc("get_random_image", params: ["category_ids": categoryIDsForRPC])
                .single() // Expecting a single row from the function
                .execute()
                .value
            
            Self.logger.info("RPC get_random_image response: ID \(imageResponse.id), Filename \(imageResponse.image_url)")

            guard let imageURL = SupabaseClient.shared.publicImageURL(filename: imageResponse.image_url) else {
                Self.logger.error("Failed to construct full URL for filename: \(imageResponse.image_url) using SupabaseClient helper")
                throw MotivDBError.urlConversionFailed
            }
            
            //Self.logger.debug("Constructed full URL via SupabaseClient helper: \(imageURL.absoluteString)")

            // --- Manual Download ---
            do {
                let (data, response) = try await URLSession.shared.data(from: imageURL)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    Self.logger.debug("Downloaded \(data.count) bytes.")
                    downloadedImageData = data
                } else if let httpResponse = response as? HTTPURLResponse {
                    Self.logger.warning("Download FAILED. Status: \(httpResponse.statusCode)")
                } else {
                    Self.logger.warning("Download FAILED. No HTTP response.")
                }
            } catch {
                Self.logger.error("Download FAILED. Error: \(error.localizedDescription)")
                // Keep downloadedImageData as nil
            }
            // Pass the imageResponse.id to the MotivationEntry
            return MotivationEntry(date: Date(), imageId: imageResponse.id, imageURL: imageURL, imageData: downloadedImageData)
        } catch let error as MotivDBError {
            Self.logger.error("MotivDBError: \(error.localizedDescription)")
            // Pass nil for imageId in error cases
            return MotivationEntry(date: Date(), imageId: nil, errorMessage: "DB Error")
        } catch {
            Self.logger.error("RPC or other error in fetchMotivationEntry: \(error.localizedDescription)")
            // Pass nil for imageId in error cases
            return MotivationEntry(date: Date(), imageId: nil, errorMessage: "Fetch Error")
        }
    }
} // Closing brace for struct Provider
