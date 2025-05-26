# Implementation Plan: Image Feedback Feature

This plan outlines the steps to add thumbs-up and thumbs-down feedback functionality to the images displayed in the MotiVate widget.

**Overall Goal:** Allow users to like or dislike an image in the widget, and have these counts reflected in the `images` table in Supabase.

## 1. Data Model Enhancement (Swift)

*   **File:** `MotivationWidgetExtension/MotivationEntry.swift`
*   **Task:** Add a property to store the unique identifier of the image.
    *   Add `let imageId: Int64?` to the `MotivationEntry` struct. (Using `Int64` to match Supabase `bigint`).
    *   Update all initializers of `MotivationEntry` to accept and set this new `imageId` property. For entries where an image ID isn't relevant (e.g., error states or static previews without a specific DB image), this can be `nil`.

## 2. Data Fetching Enhancement (Swift)

*   **File:** `MotivationWidgetExtension/Provider.swift`
*   **Task:** Pass the fetched image ID to the `MotivationEntry`.
    *   In the `fetchMotivationEntry()` function, when creating the `MotivationEntry` instance after a successful RPC call and image download, pass `imageResponse.id` to the `imageId` parameter of the `MotivationEntry` initializer.
    *   Example: `return MotivationEntry(date: Date(), imageId: imageResponse.id, imageURL: imageURL, imageData: downloadedImageData)`

## 3. Backend Logic (Supabase - PostgreSQL Function)

*   **Task:** Create a new PostgreSQL function in Supabase to handle incrementing the like/dislike counts. This ensures atomicity and centralizes the logic.
*   **Function Name (Suggestion):** `increment_image_feedback_count`
*   **Parameters:**
    *   `p_image_id BIGINT`
    *   `p_feedback_type TEXT` (e.g., 'like' or 'dislike')
*   **Logic:**
    ```sql
    CREATE OR REPLACE FUNCTION increment_image_feedback_count(p_image_id BIGINT, p_feedback_type TEXT)
    RETURNS VOID
    LANGUAGE plpgsql
    SECURITY DEFINER -- Or invoker depending on your RLS policy for the images table
    AS $$
    BEGIN
      IF p_feedback_type = 'like' THEN
        UPDATE public.images
        SET likes_count = likes_count + 1
        WHERE id = p_image_id;
      ELSIF p_feedback_type = 'dislike' THEN
        UPDATE public.images
        SET dislikes_count = dislikes_count + 1
        WHERE id = p_image_id;
      END IF;
    END;
    $$;
    ```
*   **Row Level Security (RLS):**
    *   Ensure appropriate RLS policies are on the `images` table if `SECURITY INVOKER` is used, or that the function itself handles permissions if `SECURITY DEFINER` is used. For simple incrementing, RLS on the table allowing `UPDATE` for authenticated users on the count columns might be sufficient. The function itself should be callable by authenticated users.

## 4. UI Implementation (Swift - Widget View)

*   **File:** `MotivationWidgetExtension/MotivationWidgetExtension.swift`
*   **Task:** Add thumbs-up and thumbs-down buttons to the `MotivationWidgetEntryView`.
    *   Inside the `body` of `MotivationWidgetEntryView`, overlay two buttons (e.g., using `Image(systemName: "hand.thumbsup.fill")` and `Image(systemName: "hand.thumbsdown.fill")`) on or near the displayed image.
    *   These buttons should only be visible/interactive if `entry.imageId` is not `nil` and an image (not an error message or static placeholder) is being displayed.
    *   The action of these buttons will trigger the interaction flow (see section 5).

## 5. Interaction Flow & Supabase Call (Option B - Direct Background Call from Widget via App Intent)

*   **Mechanism:** We will use an `App Intent`. This is a modern Swift concurrency feature designed for actions like this, allowing the system to manage the background execution more effectively than a simple detached `Task`.
*   **Steps:**
    1.  **Define an App Intent:**
        *   **File:** Create a new Swift file, e.g., `SubmitFeedbackIntent.swift`, within the `MotivationWidgetExtension` target.
        *   **Content:**
            ```swift
            import AppIntents
            import WidgetKit
            import Supabase // Ensure Supabase client is accessible

            struct SubmitFeedbackIntent: AppIntent {
                static var title: LocalizedStringResource = "Submit Feedback" // User-visible title if needed elsewhere

                @Parameter(title: "Image ID")
                var imageId: Int64

                @Parameter(title: "Feedback Type") // "like" or "dislike"
                var feedbackType: String

                init(imageId: Int64, feedbackType: String) {
                    self.imageId = imageId
                    self.feedbackType = feedbackType
                }

                // Conformance for App Intents that don't return a value and are used in UI like Buttons
                init() {
                    // Default initializer, parameters will be set by the Button
                    self.imageId = 0 // Default value, will be overridden
                    self.feedbackType = "" // Default value, will be overridden
                }

                @MainActor // Ensure UI updates (like timeline reload) are on the main thread
                func perform() async throws -> some IntentResult {
                    print("SubmitFeedbackIntent: Performing for imageId: \(imageId), type: \(feedbackType)")
                    do {
                        // Assuming SupabaseClient.shared.client is configured and accessible
                        try await SupabaseClient.shared.client
                            .rpc("increment_image_feedback_count", params: ["p_image_id": imageId, "p_feedback_type": feedbackType])
                            .execute()
                        print("SubmitFeedbackIntent: RPC call successful for imageId: \(imageId)")
                    } catch {
                        print("SubmitFeedbackIntent: RPC call failed for imageId: \(imageId), error: \(error.localizedDescription)")
                        // Optionally, rethrow or handle. For widgets, often just logging is feasible.
                        // throw error // If you want the system to know the intent failed
                    }

                    // Regardless of success or failure of the RPC, request a timeline reload
                    // to allow the widget to potentially reflect changes or recover.
                    WidgetCenter.shared.reloadTimelines(ofKind: "ai.myaccessibility.motivate")
                    print("SubmitFeedbackIntent: Requested timeline reload.")
                    
                    return .result() // For intents that don't return a specific value
                }
            }
            ```
    2.  **Update UI Implementation (Widget View Button Action):**
        *   **File:** `MotivationWidgetExtension/MotivationWidgetExtension.swift`
        *   **Task:** The thumbs-up/down buttons will now initialize and trigger this `SubmitFeedbackIntent`.
        *   **Example:**
            ```swift
            // Inside MotivationWidgetEntryView's body, where you add the buttons:
            if let imageId = entry.imageId { // Ensure imageId is available
                HStack {
                    Button(intent: SubmitFeedbackIntent(imageId: imageId, feedbackType: "like")) {
                        Image(systemName: "hand.thumbsup.fill")
                    }
                    .buttonStyle(.plain) // Recommended for widgets to avoid default button styling issues

                    Button(intent: SubmitFeedbackIntent(imageId: imageId, feedbackType: "dislike")) {
                        Image(systemName: "hand.thumbsdown.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
            ```

*   **Mermaid Diagram for Interaction Flow (Option B - App Intent):**
    ```mermaid
    sequenceDiagram
        participant User
        participant WidgetView
        participant SubmitFeedbackIntent
        participant SupabaseClient
        participant SupabaseDatabase
        participant WidgetCenter

        User->>WidgetView: Taps Thumbs Up (Image ID: 123)
        WidgetView->>SubmitFeedbackIntent: Initializes & Triggers Intent(imageId: 123, feedbackType: "like")
        SubmitFeedbackIntent->>SupabaseClient: Calls rpc("increment_image_feedback_count", {p_image_id:123, p_feedback_type:"like"})
        SupabaseClient->>SupabaseDatabase: Executes RPC
        SupabaseDatabase->>SupabaseDatabase: UPDATE public.images SET likes_count = likes_count + 1 WHERE id = 123
        SupabaseDatabase-->>SupabaseClient: RPC Success/Failure
        SupabaseClient-->>SubmitFeedbackIntent: Returns result
        SubmitFeedbackIntent->>WidgetCenter: reloadTimelines(ofKind: "ai.myaccessibility.motivate")
        Note over WidgetView, WidgetCenter: Widget content will refresh based on its timeline policy.
    ```

## 6. Widget Refresh

*   Regardless of the interaction flow chosen, after a feedback action is processed (either by the main app or directly by the widget), ensure the widget timeline is reloaded using `WidgetCenter.shared.reloadTimelines(ofKind: "ai.myaccessibility.motivate")`. This ensures the widget can fetch new data, although the like/dislike counts themselves won't be directly displayed on *this* widget iteration unless explicitly fetched and added to `MotivationEntry`. The primary goal here is to update the backend.

## 7. Error Handling and UX Considerations

*   **Network Errors:** Implement error handling for the Supabase RPC call (e.g., display an alert in the main app if Option A is chosen, or log thoroughly if Option B is chosen).
*   **Button Feedback:** Provide subtle visual feedback on the buttons when tapped (e.g., temporary change in opacity or scale).
*   **Preventing Double Voting (Optional - Future Enhancement):**
    *   The current backend function will increment on every call. To prevent a user from liking an image multiple times from the widget, more complex state management would be needed (either locally in the app or by designing the backend function to be idempotent for a user/image pair, which is much more complex for anonymous widget interactions). For this phase, simple increment is likely sufficient.
*   **UI State:** The buttons in the widget could potentially be disabled briefly after a tap to prevent rapid multi-tapping, though this adds complexity to the widget's state.