//
//  MotivationWidgetExtension.swift
//  MotivationWidgetExtension
//
//  Created by Chris Venter on 20/5/2025.
//
import WidgetKit
import SwiftUI

// This is the SwiftUI View for your widget
struct MotivationWidgetEntryView : View {
    var entry: Provider.Entry // The data for this specific view instance

    var body: some View {
        // DEBUG: Print the contents of the entry when the view is created
        let _ = print("MotivationWidgetEntryView - Rendering with Entry: date=\(entry.date), staticImageName=\(entry.staticPreviewImageName ?? "nil"), imageDataPresent=\(entry.imageData != nil), imageURLPresent=\(entry.imageURL != nil), errorMessage=\(entry.errorMessage ?? "nil")")

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
                // Ultimate fallback: display the static preview image
                // This handles cases where the entry might be truly empty before provider methods supply content.
                Image("WidgetPreviewImage") // Directly use the asset name
                    .resizable()
                    .scaledToFit()
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
