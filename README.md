# MotiVate - macOS Motivational Widget

A few years ago I suffered a tragic accident T=that left me paralysed from the shoulders down. There is so much about having a spinal-cord injury that most people most people (god willing) never know about.

I developed this To display uplifting and motivating messages to help those suffering Chronic pain And mental anguish associated to this kind of injury.

The application is a macOS widget that displays daily motivational images fetched from Supabase, providing inspiration right on your desktop.

## Features

- 📱 macOS Widget Support (Small, Medium, Large sizes)
- 🖼️ Dynamic motivational image loading
- 🎨 Static preview images for widget gallery
- 🔄 Automatic refresh every 1 minutes
- ⚡ Supabase integration for image storage and category data
- ✨ Category-based image filtering for personalized motivation
- ⚙️ In-app settings to select preferred image categories
- 📱 Main application now displays a motivational image based on selected categories
- 🛠️ Debug logging for development

## Requirements

- macOS 12.0 or later
- Xcode 14.0 or later
- Supabase account and project (for image storage)

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Crypto69/MotiVate.git
   cd MotiVate
   ```

2. Open the project in Xcode:
   ```bash
   open MotiVate.xcodeproj
   ```

3. Configure Supabase:
   - Add your Supabase credentials in `MotiVate/core/SupabaseClient.swift`.
   - Ensure your Supabase storage bucket (`motivational-images`) is set up with appropriate public read permissions.
   - Deploy the necessary database tables (`images`, `categories`, `image_categories`) and the `get_random_image` SQL function to your Supabase project. Refer to `supabase/migrations/` for schema details and the function definition.
 
4. Build and Run:
   - Select the `MotivationWidgetExtensionExtension` scheme
   - Choose "My Mac" as the target
   - Build and run (⌘R)

## Widget Configuration

The widget supports three sizes:
- Small (164x164)
- Medium (344x164)
- Large (344x344)

Each size displays motivational images while maintaining aspect ratio and proper scaling.

## Development

### Project Structure

- `MotiVate/`: Main app target
  - `core/`: Core functionality and shared models
    - `SupabaseClient.swift`: Handles all Supabase interactions (RPC calls, table queries).
    - `SharedModels.swift`: Defines shared data structures like `CategoryItem` and `ImageResponse`.
  - `ViewModels/`: Contains ObservableObject classes for views.
    - `CategorySettingsViewModel.swift`: Manages logic for the category selection screen.
    - `ContentViewModel.swift`: Manages logic for the main app's image display.
  - `Views/`: Contains SwiftUI views for the main application.
    - `ContentView.swift`: The main view of the application, displays an image and provides navigation.
    - `Settings/CategorySettingsView.swift`: UI for users to select preferred image categories.
  - `Models/`: May contain older or app-specific models (e.g., `CategoryItem.swift` is now a re-exporter or can be removed).
- `MotivationWidgetExtension/`: Widget extension
  - `Provider.swift`: Widget data provider, fetches images based on selected categories.
  - `MotivationEntry.swift`: Timeline entry model for the widget.
  - `MotivationWidgetExtension.swift`: Widget view and configuration.

### Key Components

- **Provider** (`MotivationWidgetExtension/Provider.swift`): Manages widget lifecycle, reads selected categories from `UserDefaults`, and fetches images via RPC.
- **MotivationEntry** (`MotivationWidgetExtension/MotivationEntry.swift`): Data model for widget content.
- **MotivationWidgetEntryView** (within `MotivationWidgetExtension.swift`): SwiftUI view for widget rendering.
- **SupabaseClient** (`MotiVate/core/SupabaseClient.swift`): Centralizes all communication with Supabase, including fetching category lists and image URLs.
- **CategorySettingsView** (`MotiVate/Views/Settings/CategorySettingsView.swift`): Allows users to select their preferred image categories.
- **CategorySettingsViewModel** (`MotiVate/ViewModels/CategorySettingsViewModel.swift`): Handles the logic for fetching categories, managing user selections, and saving them to `UserDefaults`.
- **ContentViewModel** (`MotiVate/ViewModels/ContentViewModel.swift`): Manages fetching and displaying a motivational image in the main app view, respecting selected categories.
- **SharedModels** (`MotiVate/core/SharedModels.swift`): Contains common data structures like `CategoryItem` and `ImageResponse` used by both the app and potentially the widget.

### Debug Logging

The widget includes comprehensive debug logging to assist development:
- Provider lifecycle events
- Network requests and responses
- Image loading states
- Error conditions

### Category Filtering
The application now supports filtering motivational images by category:
- Users can access a settings screen within the main MotiVate application to view all available image categories.
- They can select one or more preferred categories. These selections are saved persistently.
- The MotiVate widget reads these saved preferences.
  - If categories are selected, the widget requests an image belonging to one of those categories from the Supabase backend.
  - If no categories are selected (or if preferences haven't been set), the widget displays a random image from the entire collection.
- The main application view also displays a motivational image, respecting the user's category selections.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [Supabase](https://supabase.io/)
- Christopher Reeve Foundation for inspiration