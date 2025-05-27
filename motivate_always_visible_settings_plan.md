# Plan: Always-Visible Category Settings in MotiVate (macOS)

## Objective

Refactor the main app layout so that the `CategorySettingsView` is always visible in the right-hand detail pane, allowing users to adjust categories at any time. The left pane will display the main motivational image and quote. This will use a split view (`NavigationView` or `NavigationSplitView`) for a native macOS experience.

---

## 1. Analyze Current State

- **Current Layout:**  
  - Uses `NavigationView` with only the primary pane populated.
  - `CategorySettingsView` is presented modally as a sheet.
  - Right pane is empty and resizable, causing confusion.

---

## 2. Target Layout

- **Split View:**  
  - **Left Pane:** Main motivational content (image, quote, refresh, etc.)
  - **Right Pane:** `CategorySettingsView` always visible and interactive.

---

## 3. Refactor Steps

### Step 1: Update `ContentView.swift` Structure

- Replace the single-pane `NavigationView` with a two-pane split view.
- For modern SwiftUI (macOS 13+), prefer `NavigationSplitView`:
  ```swift
  NavigationSplitView {
      // Primary: Main content
  } detail: {
      // Detail: CategorySettingsView
  }
  ```
- For older SwiftUI, use `NavigationView` with two children:
  ```swift
  NavigationView {
      // Primary: Main content
      // Detail: CategorySettingsView
  }
  ```

### Step 2: Move `CategorySettingsView` to the Detail Pane

- Remove the `.sheet(isPresented:)` logic for settings.
- Place `CategorySettingsView()` directly in the detail pane.

### Step 3: Adjust State Management

- If `CategorySettingsView` needs to communicate with the main content (e.g., to trigger a refresh), use a shared `ObservableObject` (e.g., `ContentViewModel`) or environment object.
- Remove any state or logic related to showing/hiding the settings sheet.

### Step 4: UI/UX Polish

- Ensure the split view divider is visible and resizable.
- Optionally, set a minimum width for the detail pane for usability.
- Consider adding a title or header to the settings pane for clarity.

### Step 5: Toolbar Adjustments

- Remove the settings button from the toolbar (since settings are always visible).
- Keep the refresh button in the main content pane's toolbar if desired.

---

## 4. Example Pseudocode

```swift
NavigationSplitView {
    // Primary
    VStack {
        Text("MotiVate")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding(.top)
        // ...image/quote logic...
    }
    .toolbar {
        // Refresh button, etc.
    }
} detail: {
    CategorySettingsView()
        .frame(minWidth: 300) // Optional: set a minimum width
}
```

---

## 5. Testing & Validation

- Verify that the app launches with both panes visible.
- Confirm that category changes in the right pane update the main content as expected.
- Ensure the UI is responsive and the divider behaves as expected.
- Remove any unused state or code related to the old modal settings.

---

## 6. Rollback Plan

- If issues arise, revert to the previous layout using version control.
- Keep a backup of the original `ContentView.swift` and related files.

---

## 7. Optional Enhancements

- Add a visual indicator or title to the settings pane.
- Allow the user to collapse the settings pane if desired.
- Sync settings changes live with the main content.

---

**This plan provides a clear, step-by-step approach to refactoring your app for always-visible category settings in a native macOS split view.**