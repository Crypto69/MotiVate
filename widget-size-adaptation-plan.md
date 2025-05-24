# Plan: Dynamic Image Loading Based on Widget Size for Motivational Widget

**Objective:** Modify the motivational widget to fetch and display images optimized for the current widget family (small, medium, or large) by querying different folders within the Supabase "motivational-images" bucket.

**Assumptions:**
*   The Supabase "motivational-images" bucket will be structured with subfolders: `small/`, `medium/`, and `large/`.
*   Each subfolder will contain images appropriately sized/cropped for that widget family.
*   The main app and widget extension targets are correctly configured with App Sandbox and App Groups.

---

**Phase 1: Update Supabase Client (`MotiVate/core/SupabaseClient.swift`)**

1.  **Define an Enum for Image Sizes:**
    *   Create an `ImageSizeCategory` enum to represent the sizes for type safety. This can be placed within `SupabaseClient.swift` or a shared utility file accessible by the client.
    ```swift
    enum ImageSizeCategory: String {
        case small
        case medium
        case large
    }
    ```

2.  **Modify `randomImageURL()` function:**
    *   Change the function signature to accept the new `ImageSizeCategory`:
      `func randomImageURL(forCategory category: ImageSizeCategory) async throws -> URL`
    *   Determine the Supabase folder path based on the `category` parameter.
    *   Use this `folderPath` in the `storage.list(path: folderPath)` call.
    *   When constructing the public URL, prepend the `folderPath` to the filename: `try storage.getPublicURL(path: "\(folderPath)/\(randomFile.name)")`.
    *   Ensure robust error handling if a folder is empty (e.g., re-throw `MotivDBError.emptyBucket`).

    **Example Snippet for `randomImageURL` modification:**
    ```swift
    // Inside SupabaseClient.swift
    // ... (ImageSizeCategory enum defined above) ...

    // struct SupabaseClient { ...
        func randomImageURL(forCategory category: ImageSizeCategory) async throws -> URL {
            let folderPath = category.rawValue // "small", "medium", or "large"

            let storage = client.storage.from("motivational-images") // Bucket name

            let files: [FileObject]
            do {
                // List files within the specific category folder
                files = try await storage.list(path: folderPath)
            } catch {
                print("Error listing files in '\(folderPath)': \(error)")
                throw MotivDBError.imageFetchFailed // Or a more specific error
            }

            guard let randomFile = files.randomElement() else {
                print("The '\(folderPath)' folder in 'motivational-images' bucket is empty.")
                throw MotivDBError.emptyBucket
            }

            let fullImagePath = "\(folderPath)/\(randomFile.name)"
            let publicURL: URL
            do {
                publicURL = try storage.getPublicURL(path: fullImagePath)
            } catch {
                print("Error getting public URL for \(fullImagePath): \(error)")
                throw MotivDBError.urlConversionFailed
            }

            print("Selected image URL from '\(folderPath)': \(publicURL.absoluteString)")
            return publicURL
        }
    // ... }
    ```

---

**Phase 2: Update Timeline Provider (`MotivationWidgetExtension/Provider.swift`)**

1.  **Map `WidgetFamily` to `ImageSizeCategory`:**
    *   Create a private helper function within `Provider` to convert the system's `WidgetFamily` to your custom `ImageSizeCategory`.
    ```swift
    // Inside struct Provider: TimelineProvider { ...
    private func mapWidgetFamilyToImageCategory(_ family: WidgetFamily) -> ImageSizeCategory {
        switch family {
        case .systemSmall:
            return .small
        case .systemMedium:
            return .medium
        case .systemLarge, .systemExtraLarge: // Group systemExtraLarge with large
            return .large
        @unknown default:
            return .large // Sensible default
        }
    }
    // ... }
    ```

2.  **Modify `fetchMotivationEntry()`:**
    *   Change its signature to accept the current `WidgetFamily`:
      `private func fetchMotivationEntry(forFamily family: WidgetFamily) async -> MotivationEntry`
    *   Inside this function:
        *   Call `mapWidgetFamilyToImageCategory(family)` to get the `ImageSizeCategory`.
        *   Call the updated `SupabaseClient.shared.randomImageURL(forCategory: ...)` with the determined category.
        *   The rest of the logic (manual data download, creating `MotivationEntry` with `imageData`) remains largely the same.

3.  **Update Calls to `fetchMotivationEntry`:**
    *   In `getSnapshot(in context: ...)`:
      `let entry = await fetchMotivationEntry(forFamily: context.family)`
    *   In `getTimeline(in context: ...)`:
      `let currentEntry = await fetchMotivationEntry(forFamily: context.family)`

    **Example Snippet for `fetchMotivationEntry` modification in `Provider.swift`:**
    ```swift
    // Inside struct Provider: TimelineProvider { ...
    // ... (mapWidgetFamilyToImageCategory defined above) ...

    private func fetchMotivationEntry(forFamily family: WidgetFamily) async -> MotivationEntry {
        var downloadedImageData: Data? = nil
        let imageCategory = mapWidgetFamilyToImageCategory(family) // Determine category

        do {
            // Fetch URL for the specific image category
            let url = try await SupabaseClient.shared.randomImageURL(forCategory: imageCategory)
            print("Successfully fetched image URL for AsyncImage (category: \(imageCategory.rawValue)): \(url)")

            // Manual Download Diagnostic (remains the same)
            print("Attempting manual download of image data from: \(url)")
            // ... (existing manual download logic) ...
            // if successful: downloadedImageData = data

            return MotivationEntry(date: Date(), imageURL: url, imageData: downloadedImageData)
        } catch let error as MotivDBError {
            print("MotivDBError fetching image URL (category: \(imageCategory.rawValue)): \(error)")
            return MotivationEntry(date: Date(), errorMessage: "Error fetching URL: \(error.localizedDescription)")
        } catch {
            print("Generic error fetching image URL (category: \(imageCategory.rawValue)): \(error.localizedDescription)")
            return MotivationEntry(date: Date(), errorMessage: "Failed to get image URL.")
        }
    }
    // ... }
    ```

---

**Phase 3: Update Widget View (`MotivationWidgetExtension/MotivationWidgetExtension.swift`)**

1.  **Verify Supported Families:**
    *   Ensure your `MotivationWidget` struct still declares support for all intended sizes:
    ```swift
    // Inside struct MotivationWidget: Widget { ...
        var body: some WidgetConfiguration {
            StaticConfiguration(...) { ... }
            // ...
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        }
    // ... }
    ```
2.  **No Major View Changes Needed (Potentially):**
    *   The `MotivationWidgetEntryView` already uses `entry.imageData` and `.scaledToFit()`. If the images uploaded to Supabase for each size category are already well-suited (e.g., text is legible, composition is good for that aspect ratio), then no further changes to the view logic itself might be necessary.
    *   If you wanted different *layouts* or content entirely for different sizes (not just different image sources), you would introduce `@Environment(\.widgetFamily)` and a `switch` statement in the view's `body` as discussed previously. For this plan, we assume the primary change is the image source.

---

**Phase 4: Supabase Storage Setup**

1.  **Create Subfolders in "motivational-images" Bucket:**
    *   `small/`
    *   `medium/`
    *   `large/`
2.  **Upload Optimized Images:**
    *   Populate each folder with images that are appropriately sized, cropped, or designed for the corresponding widget family.
    *   Pay attention to aspect ratios and text legibility for smaller sizes.

---

**Phase 5: Testing**

1.  **Comprehensive Testing:**
    *   Add small, medium, and large instances of your widget to the desktop.
    *   Verify each size loads images from the correct Supabase folder (check console logs for URLs containing `/small/`, `/medium/`, or `/large/`).
    *   Ensure images display correctly and are legible for each size.
2.  **Empty Folder Test:**
    *   Temporarily remove all images from one of the size folders (e.g., `medium/`) in Supabase.
    *   Verify that the medium-sized widget displays an appropriate error/placeholder state as defined by your `MotivationEntry` and `MotivationWidgetEntryView` logic.
3.  **Network Interruption Test:**
    *   Simulate network offline conditions to confirm error handling.

---

**Considerations & Potential Enhancements:**
*   **Fallback Strategy:** If a size-specific folder is empty or an image fails to load, consider if `SupabaseClient` should attempt to fall back to a default folder (e.g., `large/`) instead of immediately showing an error.
*   **Image Caching:** The current plan relies on `URLSession`'s default caching for the manual download. For more robust caching (e.g., to reduce downloads if the same "random" image is picked again soon), implement a custom disk cache using the App Group container.
*   **Content Variation:** If simply changing the image source isn't enough for smaller sizes (e.g., text is still too small), you would then need to implement the `@Environment(\.widgetFamily)` switch in `MotivationWidgetEntryView` to render different content (e.g., an icon or a simpler view for `.systemSmall`).

This plan outlines the necessary steps to adapt your widget to serve different images based on the widget's family size.

---

**Addendum: Image Dimensions and Padding**

**1. Recommended Image Dimensions (@2x):**

It's crucial to provide images with enough resolution for Retina displays (@2x is standard, @3x for higher density if desired). The exact pixel dimensions for macOS widgets can be somewhat flexible due to system scaling, but targeting common aspect ratios is key. The following are good starting points for your @2x source images:

*   **`.systemSmall` (Approx. 1:1 Aspect Ratio):**
    *   **Target @2x Dimensions:** Around **340x340 pixels**.
    *   **Content:** For images with text, this size is very challenging. Consider highly simplified graphics, icons, or a very prominent short phrase if using an image. Test legibility rigorously.

*   **`.systemMedium` (Approx. 2:1 Aspect Ratio - Wide):**
    *   **Target @2x Dimensions:** Around **700x340 pixels**.
    *   **Content:** Can accommodate images with text, provided the text is large enough in the source image. `.scaledToFit()` will ensure visibility.

*   **`.systemLarge` (Larger Square/Slight Rectangle):**
    *   **Target @2x Dimensions:** This is the most flexible. Good starting points could be **700x700 pixels** (for squarer content) or **700x500 pixels** (for slightly wider content). Analyze the aspect ratio of your existing "large" images that you like.
    *   **Content:** Best for detailed images and more extensive text.

**Method for Refining Dimensions:**
1.  Add your widget in each supported size to your macOS desktop.
2.  Take precise screenshots. These dimensions (on a Retina Mac) are likely the @2x rendering dimensions. Use these as a strong guide for your source image assets.
3.  Always test your prepared images by loading them into the widget on a Mac to see how they actually look and fit.

**2. Handling Padding:**

SwiftUI widgets have default system-defined padding or margins around their content area.

*   **Default Behavior:** By default, your content (the `ZStack` in `MotivationWidgetEntryView`) will be inset slightly from the widget's edges. This is generally desirable as it prevents content from touching the very edge of the widget chrome. Your images, when using `.scaledToFit()` within this `ZStack`, will respect these implicit margins.

*   **Removing Default Margins (Edge-to-Edge Content):**
    If you want your image to extend to the very edges of the widget (bleed), you can use the `.containerBackgroundRemovable(false)` modifier on your `WidgetConfiguration` or `.contentMarginsDisabled()` on the `StaticConfiguration` (as commented out in your current code).
    ```swift
    // In MotivationWidget.swift
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
        MotivationWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Daily Motivation")
    .description("Shows a fresh motivational image regularly.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    // .contentMarginsDisabled() // Uncomment this for edge-to-edge content
    ```
    If you disable content margins, your `ZStack` (and thus your image if it fills the `ZStack`) will go edge-to-edge.

*   **Adding Custom Padding:**
    If you want *more* padding than the system default, or specific padding on certain sides, you would apply standard SwiftUI `.padding()` modifiers to the content *inside* your `MotivationWidgetEntryView`. For example, to add more padding around the image itself:
    ```swift
    // Inside MotivationWidgetEntryView's body
    ZStack {
        if let imageData = entry.imageData, let nsImage = NSImage(data: imageData) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .padding() // Adds default padding around the image, inside the ZStack
        }
        // ...
    }
    // ...
    ```
    However, for an image meant to be the primary background or content, you usually either rely on system margins or go edge-to-edge. Adding extra padding to an image that's already scaled to fit might make it unnecessarily small unless that's a specific design choice.

**Recommendation on Padding for Your Image Widget:**
*   Start with the **default system margins** (i.e., don't use `.contentMarginsDisabled()`). This usually provides a visually pleasing inset.
*   Ensure your images for each size category are designed to look good within the aspect ratio of that widget family, considering these default margins.
*   If, after testing, you find the default margins are too large for your aesthetic, then you can experiment with `.contentMarginsDisabled()` and see if your images look better extending to the edges. Be mindful that text near edges can sometimes be less comfortable to read.

The key is to design your image assets for the target aspect ratios and test visually. The `.scaledToFit()` modifier will handle the fitting, and system margins (or lack thereof if disabled) will define the outer boundary.

---

**Addendum 2: Widget Icon and Deployment/Sharing**

**1. Adding an Icon for the Widget (Widget Gallery Icon):**

The icon that appears next to your widget's name ("Daily Motivation") in the widget gallery is typically derived from the **main application's icon**.

*   **Ensure Main App Has an Icon:** Your main macOS application (e.g., "MotiVate") must have a proper App Icon set in its `Assets.xcassets` file.
    *   In Xcode, navigate to `MotiVate/Assets.xcassets`.
    *   Select the `AppIcon` asset.
    *   Drag and drop appropriately sized versions of your app icon into the designated slots (e.g., 16x16, 32x32, 128x128, 256x256, 512x512, 1024x1024 for @1x and @2x). Xcode uses these to generate the necessary `AppIcon.icns` file.
*   **System Handles It:** macOS will then usually pick a suitable representation from your main app's icon to display in the widget gallery. There isn't a separate, dedicated "widget gallery icon" asset you typically provide directly for the widget extension itself in the same way you do for the main app.
*   **Widget Extension's Assets:** The `Assets.xcassets` inside your `MotivationWidgetExtension` folder is generally for assets used *within* the widget's view (e.g., if you had a static placeholder image you wanted to bundle, or custom symbols). It's not typically used for the gallery icon.

**If the gallery icon isn't appearing or looks wrong:**
*   Double-check that your main app's `AppIcon` set is complete and correctly configured.
*   Clean the build folder and rebuild.
*   Sometimes, macOS caches widget gallery information. A restart of your Mac or waiting some time might be needed for changes to fully propagate.

**2. Deploying and Sharing Your Widget:**

Widgets are not standalone entities; they are **bundled with and distributed as part of a main application.**

*   **How it Works:** When a user installs your main macOS application (e.g., "MotiVate.app"), the system also registers the widget extension ("MotivationWidgetExtension.appex") contained within it. The widget then becomes available in the user's widget gallery.
*   **To Share with Another Person:** You need to share your main application (`MotiVate.app`) with them.

**Methods for Distributing/Sharing Your macOS Application (and thus the widget):**

*   **a. Mac App Store (Recommended for Broad Distribution):**
    1.  **Enroll in Apple Developer Program:** This is required.
    2.  **Archive Your App:** In Xcode, select Product > Archive. This creates a build suitable for distribution.
    3.  **App Store Connect:** Upload the archive to App Store Connect.
    4.  **Metadata and Submission:** Provide app details, screenshots, pricing, etc., and submit for review.
    5.  **Distribution:** Once approved, users can download your app (and its widget) from the Mac App Store.

*   **b. Developer ID (Distribute Outside the Mac App Store):**
    This allows users to download your app directly from your website or other means, while still being notarized by Apple for security.
    1.  **Enroll in Apple Developer Program.**
    2.  **Configure Developer ID Signing:** In Xcode's "Signing & Capabilities" for your main app target, ensure it's signed with your Developer ID certificate.
    3.  **Archive Your App:** Product > Archive.
    4.  **Notarize the App:** From the Xcode Organizer, select the archive and choose "Distribute App." Select "Developer ID" and "Upload" (to send to Apple for notarization). Apple will scan it for malicious software.
    5.  **Export the Notarized App:** Once notarization is complete, export the app (e.g., as a `.app` file or within a `.dmg` disk image).
    6.  **Distribution:** You can then host this exported `.app` (usually zipped or in a `.dmg`) for others to download and install. When they run it, Gatekeeper will verify its notarization.

*   **c. Ad Hoc / Direct Sharing (For Testing/Few Users - Less Secure for Recipients):**
    1.  **Archive Your App:** Product > Archive.
    2.  **Export for Development:** From the Xcode Organizer, you can choose "Distribute App" and select "Copy App". This gives you the `.app` bundle.
    3.  **Share:** You can then compress this `.app` file (e.g., into a `.zip`) and share it directly (e.g., via AirDrop, email, cloud storage).
    4.  **Recipient's Mac:** The recipient will likely need to adjust their System Settings > Privacy & Security settings to allow apps downloaded from identified developers or "App Store and identified developers". They might also need to right-click (or Control-click) the app and choose "Open" the first time to bypass Gatekeeper warnings if it's not notarized. This method is generally not recommended for widespread distribution due to the security hurdles for the user.

**In summary for sharing:**
*   To share your widget, you distribute the main `MotiVate.app`.
*   For easy and trusted sharing, notarizing with a Developer ID (Option b) is the minimum for distributing outside the App Store.
*   The Mac App Store (Option a) is the most streamlined for users.

This information should cover how to set an icon and the various ways to get your application (and its embedded widget) to other users.