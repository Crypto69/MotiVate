//
//  MotivationEntry.swift
//  MotivationWidgetExtensionExtension
//
//  Created by Chris Venter on 20/5/2025.
//

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
        // Now defaults to showing the static preview image for any placeholder state
        MotivationEntry.staticWidgetPreview
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
