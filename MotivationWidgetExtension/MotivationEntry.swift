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
    let imageId: Int64? // NEW: The ID of the image from the database
    let imageURL: URL? // The URL of the motivational image
    let imageData: Data? // Holds the manually downloaded image data
    let errorMessage: String? // Optional error message for debugging or display
    let staticPreviewImageName: String? // NEW: For static preview from Assets

    // Convenience initializer for success cases (dynamic image)
    init(date: Date, imageId: Int64?, imageURL: URL?, imageData: Data? = nil, errorMessage: String? = nil) { // Added imageId
        self.date = date
        self.imageId = imageId // Store imageId
        self.imageURL = imageURL
        self.imageData = imageData
        self.errorMessage = errorMessage
        self.staticPreviewImageName = nil // Ensure nil for dynamic images
    }

    // Convenience initializer for error cases
    init(date: Date, imageId: Int64? = nil, errorMessage: String) { // Added imageId, defaults to nil
        self.date = date
        self.imageId = imageId // Store imageId (usually nil for errors)
        self.imageURL = nil
        self.imageData = nil
        self.errorMessage = errorMessage
        self.staticPreviewImageName = nil // Ensure nil for error messages
    }

    // NEW: Convenience initializer for static preview image
    init(date: Date, imageId: Int64? = nil, staticPreviewImageName: String) { // Added imageId, defaults to nil
        self.date = date
        self.imageId = imageId // Store imageId (usually nil for static previews not tied to a DB image)
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
         MotivationEntry(date: Date(), imageId: nil, errorMessage: "Fetching image...") // Pass nil for imageId
    }

    // NEW: Static entry for the visual preview in the gallery
    static var staticWidgetPreview: MotivationEntry {
        MotivationEntry(date: Date(), imageId: nil, staticPreviewImageName: "WidgetPreviewImage") // Pass nil for imageId, Assumes "WidgetPreviewImage" is the name in Assets
    }
}
