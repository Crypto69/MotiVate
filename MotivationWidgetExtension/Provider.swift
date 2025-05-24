//
//  Provider.swift
//  MotiVate
//
//  Created by Chris Venter on 20/5/2025.
//

import WidgetKit
import SwiftUI // For potential use, though not strictly necessary here

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
            let currentEntry = await fetchMotivationEntry() // RESTORED CALL
            // For this widget, we'll refresh according to the policy.
            // Let's set a refresh policy, e.g., 1 minutes from now or .atEnd
            let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
            let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdateDate))
            // Simplified log for successful timeline creation
            print("Provider: getTimeline - created timeline. Entry date: \(currentEntry.date), Has image data: \(currentEntry.imageData != nil), Error: \(currentEntry.errorMessage ?? "nil")")
            completion(timeline)
        }
    }

    // Helper function - RESTORING to original implementation
    private func fetchMotivationEntry() async -> MotivationEntry {
        print("Provider: fetchMotivationEntry() called.") // Simplified log
        var downloadedImageData: Data? = nil

        do {
            let url = try await SupabaseClient.shared.randomImageURL()
             // Log only last part of URL for brevity, SupabaseClient already logs the full one.
            print("Provider: fetchMotivationEntry - Fetched URL ending with: \(url.lastPathComponent)")

            // --- Manual Download ---
            // print("Provider: fetchMotivationEntry - Attempting manual download...") // Verbose, can be enabled if needed
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                     print("Provider: fetchMotivationEntry - Downloaded \(data.count) bytes.")
                    downloadedImageData = data
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("Provider: fetchMotivationEntry - Download FAILED. Status: \(httpResponse.statusCode)")
                } else {
                    print("Provider: fetchMotivationEntry - Download FAILED. No HTTP response.")
                }
            } catch {
                // Log only the localized description for brevity
                print("Provider: fetchMotivationEntry - Download FAILED. Error: \(error.localizedDescription)")
            }
            return MotivationEntry(date: Date(), imageURL: url, imageData: downloadedImageData)
        } catch let error as MotivDBError {
            // Log only the localized description
            print("Provider: fetchMotivationEntry - MotivDBError: \(error.localizedDescription)")
            return MotivationEntry(date: Date(), errorMessage: "DB Error") // Shorter error message for display
        } catch {
            // Log only the localized description
            print("Provider: fetchMotivationEntry - Generic error: \(error.localizedDescription)")
            return MotivationEntry(date: Date(), errorMessage: "Fetch Error") // Shorter error message for display
        }
    }


} // Closing brace for struct Provider
