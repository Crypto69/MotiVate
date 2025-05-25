//
//  Provider.swift
//  MotiVate
//
//  Created by Chris Venter on 20/5/2025.
//

import WidgetKit
import SwiftUI // For potential use, though not strictly necessary here
import Supabase // Required for RPC calls

// ImageResponse struct is now defined in MotiVate/core/SharedModels.swift
// Ensure SharedModels.swift is included in this widget extension's target membership.
 
struct Provider: TimelineProvider {
    // Explicit initializer to check if Provider is even being created
    init() {
        print("Provider: init() called.") // Simplified log
    }

    // Provides a placeholder version of the widget.
    func placeholder(in context: Context) -> MotivationEntry {
        print("Provider: placeholder(in:) called. Family: \(context.family), isPreview: \(context.isPreview)") // Simplified log
        return MotivationEntry.staticWidgetPreview // Keep using static preview for gallery
    }

    // Provides a snapshot of the widget's content.
    func getSnapshot(in context: Context, completion: @escaping (MotivationEntry) -> Void) {
        print("Provider: getSnapshot(in:completion:) called. Family: \(context.family), isPreview: \(context.isPreview)") // Simplified log
        if context.isPreview {
            print("Provider: getSnapshot - isPreview is true, returning staticWidgetPreview.") // Simplified log
            completion(MotivationEntry.staticWidgetPreview)
            return
        }
        // For non-preview snapshot, immediately return the staticWidgetPreview.
        // getTimeline will be called shortly after to fetch the first real image.
        print("Provider: getSnapshot - isPreview is false, returning staticWidgetPreview immediately.") // DEBUG
        completion(MotivationEntry.staticWidgetPreview)
    }

    // Provides an array of timeline entries.
    func getTimeline(in context: Context, completion: @escaping (Timeline<MotivationEntry>) -> Void) {
        print("Provider: getTimeline called. Family: \(context.family), isPreview: \(context.isPreview). Will call fetchMotivationEntry.") // Simplified log
        Task {
            let currentEntry = await fetchMotivationEntry()
            // For this widget, we'll refresh according to the policy.
            // Let's set a refresh policy, e.g., 1 minutes from now or .atEnd
            let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
            let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdateDate))
            // Simplified log for successful timeline creation
            print("Provider: getTimeline - created timeline. Entry date: \(currentEntry.date), Has image data: \(currentEntry.imageData != nil), Error: \(currentEntry.errorMessage ?? "nil")")
            completion(timeline)
        }
    }

    private func fetchMotivationEntry() async -> MotivationEntry {
        print("Provider: fetchMotivationEntry() called.")
        var downloadedImageData: Data? = nil
        
        let appGroupID = "group.ai.myaccessibility.motivate"
        let userDefaults = UserDefaults(suiteName: appGroupID)
        
        let selectedCategoryIDsStrings = userDefaults?.stringArray(forKey: "selectedCategoryIDs") ?? []
        let categoryIDsForRPC: [Int64]? = selectedCategoryIDsStrings.isEmpty ? nil : selectedCategoryIDsStrings.compactMap { Int64($0) }

        print("Provider: fetchMotivationEntry - Selected category IDs for RPC: \(categoryIDsForRPC?.map { String($0) }.joined(separator: ", ") ?? "None (fully random)")")

        do {
            // Call the RPC function "get_random_image"
            // Assuming SupabaseClient.shared.client is the Supabase.SupabaseClient instance
            // The type ImageResponse should now resolve from the shared MotiVate/core/SharedModels.swift
            let imageResponse: ImageResponse = try await SupabaseClient.shared.client
                .rpc("get_random_image", params: ["category_ids": categoryIDsForRPC])
                .single() // Expecting a single row from the function
                .execute()
                .value
            
            print("Provider: fetchMotivationEntry - RPC Response: ID \(imageResponse.id), Filename \(imageResponse.image_url)")

            guard let imageURL = SupabaseClient.shared.publicImageURL(filename: imageResponse.image_url) else {
                print("Provider: fetchMotivationEntry - Failed to construct full URL for filename: \(imageResponse.image_url) using SupabaseClient helper")
                throw MotivDBError.urlConversionFailed
            }
            
            print("Provider: fetchMotivationEntry - Constructed full URL via SupabaseClient helper: \(imageURL.absoluteString)")

            // --- Manual Download ---
            do {
                let (data, response) = try await URLSession.shared.data(from: imageURL)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Provider: fetchMotivationEntry - Downloaded \(data.count) bytes.")
                    downloadedImageData = data
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("Provider: fetchMotivationEntry - Download FAILED. Status: \(httpResponse.statusCode)")
                } else {
                    print("Provider: fetchMotivationEntry - Download FAILED. No HTTP response.")
                }
            } catch {
                print("Provider: fetchMotivationEntry - Download FAILED. Error: \(error.localizedDescription)")
                // Keep downloadedImageData as nil
            }
            // Note: MotivationEntry does not currently store image ID, likes, or dislikes.
            // This is fine for Phase One.
            return MotivationEntry(date: Date(), imageURL: imageURL, imageData: downloadedImageData)
        } catch let error as MotivDBError {
            print("Provider: fetchMotivationEntry - MotivDBError: \(error.localizedDescription)")
            return MotivationEntry(date: Date(), errorMessage: "DB Error")
        } catch {
            print("Provider: fetchMotivationEntry - RPC or other error: \(error.localizedDescription)")
            return MotivationEntry(date: Date(), errorMessage: "Fetch Error")
        }
    }
} // Closing brace for struct Provider
