# Plan: Add "About" Menu Item to Primary View in MotiVate

## Objective

Add an "About" menu item at the top of the primary (left) pane above the motivational image. When clicked, this should display a modal or sheet with information about the author (Chris Venter) and instructions for submitting images and quotes for review.

---

## 1. UI/UX Design

- Place an "About" button or menu at the top of the primary content area (above the image/quote).
- When the user clicks "About", present a modal sheet or popover.
- The modal should contain:
  - Author information (Chris Venter)
  - Instructions for submitting images/quotes

---

## 2. Implementation Steps

### Step 1: Add State to Control About Modal

- In `ContentView`, add a `@State private var showingAbout = false`.

### Step 2: Add "About" Button to Primary View

- At the top of the primary `VStack` in `ContentView`, add a button labeled "About".
- The button should set `showingAbout = true` when clicked.

### Step 3: Create `AboutView`

- Create a new SwiftUI view called `AboutView`.
- This view should display:
  - Author: Chris Venter
  - A short bio or description (optional)
  - Instructions for submitting images/quotes (e.g., email address, link, or in-app submission instructions)

### Step 4: Present `AboutView` as a Sheet

- In `ContentView`, use `.sheet(isPresented: $showingAbout)` to present `AboutView` when the "About" button is clicked.

### Step 5: Polish and Test

- Ensure the "About" button is visually distinct but not distracting.
- Test that the modal displays correctly and is dismissible.
- Confirm that the information is clear and actionable.

---

## 3. Example UI Structure

```swift
VStack {
    HStack {
        Button("About") {
            showingAbout = true
        }
        .buttonStyle(.bordered)
        Spacer()
    }
    .padding([.top, .horizontal])

    // ... rest of motivational image/quote content ...
}
.sheet(isPresented: $showingAbout) {
    AboutView()
}
```

---

## 4. AboutView Content Example

```swift
struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About MotiVate")
                .font(.title)
                .bold()
            Text("Author: Chris Venter")
                .font(.headline)
            Text("MotiVate is designed to inspire and motivate through curated images and quotes.")
            Divider()
            Text("Submit Your Own Images & Quotes")
                .font(.headline)
            Text("To submit your own motivational images or quotes for review, please email them to motivate@example.com or visit our website at motivate.app/submit.")
            Spacer()
            Button("Close") {
                // Dismiss logic handled by sheet
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}
```

---

## 5. Edge Cases & Considerations

- Ensure the sheet is accessible and dismissible.
- The "About" button should not interfere with the main content.
- Optionally, add keyboard shortcuts or accessibility labels.

---

**This plan provides a clear, step-by-step approach to adding an "About" menu item to the primary view in MotiVate.**