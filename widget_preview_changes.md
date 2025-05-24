# Proposed Changes for Widget Static Preview

This document outlines the proposed code changes to implement a static preview image for the MotiVate widget.

**Important Pre-requisite:** Ensure you have added your `preview-image.png` to the `MotivationWidgetExtension/Assets.xcassets` and named the asset `WidgetPreviewImage`.

## 1. `MotivationWidgetExtension/MotivationEntry.swift`

```swift
// MotivationEntry.swift
import WidgetKit
import Foundation // For URL and Date

struct MotivationEntry: TimelineEntry {
    let date: Date     // The time at which this entry should be displayed
    let imageURL: URL? // The URL of the motivational image
    let imageData: Data? // Holds the manually downloaded image data
    let errorMessage: String? // Optional error message for debugging or display
    let staticPreviewImageName: String? // NEW: For static preview from Assets

    // Convenience initializer for success cases (dynamic image)
    init(date: Date, imageURL: URL?, imageData: Data? = nil, errorMessage: String? = nil) {
        self.date = date
        self.imageURL = imageURL
        self.imageData = imageData
        self.errorMessage = errorMessage
        self.staticPreviewImageName = nil // Ensure nil for dynamic images
    }

    // Convenience initializer for error cases
    init(date: Date, errorMessage: String) {
        self.date = date
        self.imageURL = nil
        self.imageData = nil
        self.errorMessage = errorMessage
        self.staticPreviewImageName = nil // Ensure nil for error messages
    }

    // NEW: Convenience initializer for static preview image
    init(date: Date, staticPreviewImageName: String) {
        self.date = date
        self.imageURL = nil
        self.imageData = nil
        self.errorMessage = nil
        self.staticPreviewImageName = staticPreviewImageName
    }

    // Static placeholder for gallery (initial loading state)
    static var placeholder: MotivationEntry {
        MotivationEntry(date: Date(), errorMessage: "Loading...")
    }

    // Static snapshot entry for transient situations (fetching state)
    // We might revise this later to also use staticWidgetPreview if context.isPreview is true
    static var snapshot: MotivationEntry {
         MotivationEntry(date: Date(), errorMessage: "Fetching image...")
    }

    // NEW: Static entry for the visual preview in the gallery
    static var staticWidgetPreview: MotivationEntry {
        MotivationEntry(date: Date(), staticPreviewImageName: "WidgetPreviewImage") // Assumes "WidgetPreviewImage" is the name in Assets
    }
}
```

## 2. `MotivationWidgetExtension/Provider.swift`

```swift
// Provider.swift
import WidgetKit
import SwiftUI // For potential use, though not strictly necessary here

struct Provider: TimelineProvider {
    // Provides a placeholder version of the widget.
    // Displayed in the widget gallery before the widget loads real data.
    func placeholder(in context: Context) -> MotivationEntry {
        // For the initial placeholder in the gallery, let's show the actual preview image
        return MotivationEntry.staticWidgetPreview // CHANGED
    }

    // Provides a snapshot of the widget's content for transient situations (e.g., widget gallery).
    // Aim for a quick response; if fetching data is slow, provide sample data.
    func getSnapshot(in context: Context, completion: @escaping (MotivationEntry) -> Void) {
        // If context.isPreview is true, you're in the widget gallery.
        // You might want to return a specific sample image or mock data quickly.
        if context.isPreview {
            // For the gallery snapshot, also show the actual preview image
            completion(MotivationEntry.staticWidgetPreview) // CHANGED
            return
        }

        // For a real snapshot, attempt a quick fetch or use a cached entry if available.
        Task {
            let entry = await fetchMotivationEntry()
            completion(entry)
        }
    }

    // Provides an array of timeline entries, current and future.
    // WidgetKit will display these entries according to their specified dates.
    func getTimeline(in context: Context, completion: @escaping (Timeline<MotivationEntry>) -> Void) {
        Task {
            // 1. Fetch the current motivational entry
            let currentEntry = await fetchMotivationEntry()

            // 2. Determine the next update time
            // For this widget, we'll refresh every 30 seconds.
            let nextUpdateDate = Calendar.current.date(byAdding: .second, value: 30, to: Date())!

            // 3. Create the timeline
            let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdateDate))
            completion(timeline)
        }
    }

    // Helper function to fetch the data using our SupabaseClient
    private func fetchMotivationEntry() async -> MotivationEntry {
        var downloadedImageData: Data? = nil // Variable to store manually downloaded data

        do {
            let url = try await SupabaseClient.shared.randomImageURL()
            print("Successfully fetched image URL for AsyncImage: \(url)")

            // --- Manual Download Diagnostic ---
            print("Attempting manual download of image data from: \(url)")
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Manual download: HTTP Status Code: 200")
                    print("Manual download: Successfully downloaded \(data.count) bytes.")
                    downloadedImageData = data // Store the successfully downloaded data
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("Manual download: FAILED. HTTP Status Code: \(httpResponse.statusCode)")
                } else {
                    print("Manual download: FAILED. No HTTP response.")
                }
            } catch {
                print("Manual download: FAILED. Error: \(error.localizedDescription)\nFull manual download error: \(error)")
            }
            // --- End Manual Download Diagnostic ---

            // Return entry with the imageURL and the manually downloaded imageData (if any)
            return MotivationEntry(date: Date(), imageURL: url, imageData: downloadedImageData)

        } catch let error as MotivDBError {
            print("MotivDBError fetching image URL: \(error)")
            return MotivationEntry(date: Date(), errorMessage: "Error fetching URL: \(error.localizedDescription)")
        } catch {
            print("Generic error fetching image URL: \(error.localizedDescription)")
            return MotivationEntry(date: Date(), errorMessage: "Failed to get image URL.")
        }
    }
}
```

## 3. `MotivationWidgetExtension/MotivationWidgetExtension.swift`

```swift
// MotivationWidget.swift
import WidgetKit
import SwiftUI

// This is the SwiftUI View for your widget
struct MotivationWidgetEntryView : View {
    var entry: Provider.Entry // The data for this specific view instance

    var body: some View {
        ZStack {
            // NEW: Prioritize static preview image if available
            if let staticImageName = entry.staticPreviewImageName {
                Image(staticImageName) // Assumes "WidgetPreviewImage" is in Assets
                    .resizable()
                    .scaledToFit() // Or .fill, adjust as needed
            }
            // Display image from manually downloaded data if available
            else if let imageData = entry.imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
            }
            // Display error message if an error occurred
            else if let errorMessage = entry.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 5)
                        .padding(.top, 2)
                }
            }
            // Default placeholder if no image data and no specific error
            else {
                ProgressView()
            }
        }
        .widgetURL(URL(string: "motivationalwidget://open"))
        .clipped()
        .containerBackground(for: .widget) {
            Color.gray.opacity(0.1)
        }
    }
}

// This is the main Widget configuration
@main
struct MotivationWidget: Widget {
    let kind: String = "ai.myaccessibility.motivate"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MotivationWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Motivation")
        .description("Shows a fresh motivational image regularly.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Optional: Previews for Xcode canvas
struct MotivationWidget_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with imageData
        let sampleImageData: Data? = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)?
            .tiffRepresentation
        
        let placeholderEntryWithData = MotivationEntry(
            date: Date(),
            imageURL: nil,
            imageData: sampleImageData
        )

         let errorEntry = MotivationEntry(
            date: Date(),
            errorMessage: "Preview Error: Image not found."
        )
        
        let loadingEntry = MotivationEntry(
            date: Date(),
            imageURL: URL(string: "https://example.com/loading.jpg"),
            imageData: nil,
            errorMessage: nil
        )

        // NEW: Preview for the static widget preview
        let staticPreviewEntry = MotivationEntry.staticWidgetPreview

        Group { // Use Group for multiple previews
            MotivationWidgetEntryView(entry: staticPreviewEntry) // NEW
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Preview (Static)")

            MotivationWidgetEntryView(entry: placeholderEntryWithData)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Preview (Data)")

            MotivationWidgetEntryView(entry: errorEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small Preview (Error)")
            
            MotivationWidgetEntryView(entry: loadingEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Preview (Loading)")
        }
    }
}