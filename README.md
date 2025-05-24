# MotiVate - macOS Motivational Widget

A few years ago I suffered a tragic accident T=that left me paralysed from the shoulders down. There is so much about having a spinal-cord injury that most people most people (god willing) never know about.

I developed this To display uplifting and motivating messages to help those suffering Chronic pain And mental anguish associated to this kind of injury.

The application is a macOS widget that displays daily motivational images fetched from Supabase, providing inspiration right on your desktop.

## Features

- 📱 macOS Widget Support (Small, Medium, Large sizes)
- 🖼️ Dynamic motivational image loading
- 🎨 Static preview images for widget gallery
- 🔄 Automatic refresh every 1 minutes
- ⚡ Supabase integration for image storage
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
   - Add your Supabase credentials in `MotiVate/core/SupabaseClient.swift`
   - Ensure your Supabase storage bucket is set up with appropriate permissions

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
  - `core/`: Core functionality
    - `SupabaseClient.swift`: Supabase integration
- `MotivationWidgetExtension/`: Widget extension
  - `Provider.swift`: Widget data provider
  - `MotivationEntry.swift`: Timeline entry model
  - `MotivationWidgetExtension.swift`: Widget view and configuration

### Key Components

- **Provider**: Manages widget lifecycle and data fetching
- **MotivationEntry**: Data model for widget content
- **MotivationWidgetEntryView**: SwiftUI view for widget rendering

### Debug Logging

The widget includes comprehensive debug logging to assist development:
- Provider lifecycle events
- Network requests and responses
- Image loading states
- Error conditions

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