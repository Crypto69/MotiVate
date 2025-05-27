//
//  SubmitFeedbackIntent.swift
//  MotivationWidgetExtension
//
//  Created by Roo on 26/5/2025.
//

import AppIntents
import WidgetKit
import Supabase // Ensure Supabase client is accessible from your widget extension target
import os // Import the os framework for Logger

// Define a struct for the RPC parameters to ensure Encodable conformance
private struct FeedbackRpcParams: Encodable {
    let p_image_id: Int
    let p_feedback_type: String
}

struct SubmitFeedbackIntent: AppIntent {
    // Create a logger instance for this intent.
    // Replace "com.yourapp.widgetextension" with your actual bundle identifier for the extension if desired,
    // or use a unique subsystem string.
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MotivationWidgetExtension", category: "SubmitFeedbackIntent")

    // User-visible title for the intent, e.g., if it were to appear in Shortcuts.
    static var title: LocalizedStringResource = "Submit Image Feedback"

    // Parameter for the ID of the image being rated.
    // AppIntents work best with standard types like Int.
    @Parameter(title: "Image ID")
    var imageId: Int // Changed from Int64 to Int

    // Parameter for the type of feedback: "like" or "dislike".
    @Parameter(title: "Feedback Type")
    var feedbackType: String

    // Initializer used by the system when the intent is triggered, e.g., from a Button.
    // The parameters will be supplied by the Button's intent configuration.
    init(imageId: Int, feedbackType: String) { // Changed from Int64 to Int
        self.imageId = imageId
        self.feedbackType = feedbackType
    }

    // Default initializer required for AppIntent conformance, especially when used
    // directly in SwiftUI Button(intent:).
    // The actual values will be overridden by the specific intent instance created by the button.
    init() {
        self.imageId = 0 // Default/placeholder value
        self.feedbackType = "" // Default/placeholder value
    }

    // The main logic of the intent. This is executed when the intent is performed.
    // Marked @MainActor to ensure any UI-related updates (like timeline reloads)
    // are dispatched on the main thread.
    @MainActor
    func perform() async throws -> some IntentResult {
        // Use the logger instead of print
        Self.logger.info("Performing for imageId: \(self.imageId), type: \(self.feedbackType)")

        // Ensure SupabaseClient.shared.client is properly initialized and accessible.
        // This typically involves setting up the Supabase client in your App's AppDelegate
        // or in a shared location accessible by both the app and the extension.
        // Ensure the Supabase URL and anon key are correctly configured.
        
        // Assuming SupabaseClient.shared.client is non-optional and initialized elsewhere.
        // If it can indeed be nil, its declaration should be `SupabaseClient?` and
        // proper nil handling or optional chaining would be required.
        // The build error indicated it's not optional, so we use it directly.
        let supabase = SupabaseClient.shared.client

        do {
            // Call the PostgreSQL function `increment_image_feedback_count` via RPC.
            // Create an instance of our Encodable params struct.
            let rpcParams = FeedbackRpcParams(p_image_id: imageId, p_feedback_type: feedbackType)
            Self.logger.debug("Calling RPC increment_image_feedback_count with params: \(String(describing: rpcParams))") // Use debug for more verbose info
            try await supabase
                .rpc("increment_image_feedback_count", params: rpcParams)
                .execute() // Use .execute() for functions that don't return a value or if you don't need the value.
            
            Self.logger.info("RPC increment_image_feedback_count successful for imageId: \(self.imageId), type: \(self.feedbackType)")
        } catch {
            Self.logger.error("RPC call failed for imageId: \(self.imageId), type: \(self.feedbackType). Error: \(error.localizedDescription)")
            // Rethrow the error so the system is aware the intent encountered an issue.
            // This can be useful for debugging or if the system provides UI for failed intents.
            throw error
        }

        // If the RPC call was successful, we can return a successful result.
        
        // Return a successful result for the intent.
        // If your intent is designed to return data, you would use .result(value: YourData)
        return .result()
    }
}