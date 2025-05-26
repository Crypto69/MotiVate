//
//  MotivationWidgetExtension.swift
//  MotivationWidgetExtension
//
//  Created by Chris Venter on 20/5/2025.
//
import WidgetKit
import SwiftUI
import os // Import the os framework for Logger

// This is the SwiftUI View for your widget
struct MotivationWidgetEntryView : View {
    // Create a logger instance for this view.
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MotivationWidgetExtension", category: "MotivationWidgetEntryView")
    var entry: Provider.Entry // The data for this specific view instance

    var body: some View {
        // Log the entry details when the view is rendering using the `let _ = ...` pattern
        let _ = Self.logger.debug("""
            Rendering MotivationWidgetEntryView with Entry:
            Date: \(self.entry.date.description),
            ImageID: \(String(describing: self.entry.imageId)),
            StaticImageName: \(self.entry.staticPreviewImageName ?? "nil"),
            ImageDataPresent: \(self.entry.imageData != nil),
            ImageURLPresent: \(self.entry.imageURL != nil),
            ErrorMessage: \(self.entry.errorMessage ?? "nil")
            """)

        ZStack(alignment: .bottomTrailing) { // Align feedback buttons to bottom trailing
            // Group for the main image content
            Group {
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
                // Ultimate fallback: display the static preview image
                // This handles cases where the entry might be truly empty before provider methods supply content.
                Image("WidgetPreviewImage") // Directly use the asset name
                    .resizable()
                    .scaledToFit()
                }
            } // End of Group for main image content

            // Overlay for Feedback Buttons
            // Show buttons only if there's an imageId and actual imageData (i.e., not a static placeholder or error view)
            // Show buttons only if there's an imageId (which is Int64?) and actual imageData.
            // We also need to ensure we can convert imageId to Int for the SubmitFeedbackIntent.
            if let imageId64 = entry.imageId,
               let imageIdInt = Int(exactly: imageId64), // Safely convert Int64 to Int
               entry.imageData != nil,
               entry.staticPreviewImageName == nil,
               entry.errorMessage == nil {
                HStack(spacing: 10) { // Horizontal stack for buttons
                    Button(intent: SubmitFeedbackIntent(imageId: imageIdInt, feedbackType: "like")) {
                        Image(systemName: "hand.thumbsup.fill")
                            .foregroundColor(.green) // Optional: Color the icon
                    }
                    .buttonStyle(.plain) // Use plain style for better appearance in widgets

                    Button(intent: SubmitFeedbackIntent(imageId: imageIdInt, feedbackType: "dislike")) {
                        Image(systemName: "hand.thumbsdown.fill")
                            .foregroundColor(.red) // Optional: Color the icon
                    }
                    .buttonStyle(.plain)
                }
                .padding(8) // Add some padding around the buttons
                .background(.thinMaterial) // Add a subtle background for better visibility
                .clipShape(Capsule()) // Make it rounded
                .padding(10) // Padding from the ZStack edges
            }
        }
        .widgetURL(URL(string: "motivationalwidget://open")) // This makes the whole widget tappable to open the app
        .clipped()
        .containerBackground(for: .widget) {
            Color.gray.opacity(0.1) // Existing background
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
            imageId: 123, // Example imageId for preview
            imageURL: nil,
            imageData: sampleImageData
        )

         let errorEntry = MotivationEntry(
            date: Date(),
            imageId: nil, // No imageId for error entry
            errorMessage: "Preview Error: Image not found."
        )
        
        let loadingEntry = MotivationEntry(
            date: Date(),
            imageId: nil, // No imageId for loading entry (as image isn't loaded yet)
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
