# Offline Images Setup Guide

This guide explains how to set up offline fallback images for the MotiVate application.

## Overview

The app now supports offline fallback images that will be displayed when there's no internet connection. These images are bundled with the application and provide a seamless experience even when offline.

## Steps to Add Offline Images

### 1. Prepare Your Images

- **Supported formats**: .jpg, .jpeg, .png
- **Recommended size**: 1024x1024 or larger for best quality across all widget sizes
- **File naming**: Use descriptive names (e.g., "motivation-courage-1.jpg", "strength-quote-2.png")

### 2. Add Images to the Project (IMPORTANT)

Using the shared directory approach, you only need to add images once, but to BOTH targets:

#### Single Directory, Dual Target Approach:
1. In Xcode, right-click on `MotiVate/OfflineImages/` folder
2. Select "Add Files to 'MotiVate'"
3. Choose your image files
4. **CRITICAL**: In the "Add to target" section, make sure BOTH targets are checked:
   - ✅ **MotiVate** (main app)
   - ✅ **MotivationWidgetExtension** (widget)

This approach means:
- ✅ Single copy of each image file
- ✅ Both targets can access the same images
- ✅ Easier to maintain and update
- ✅ No duplicate files in your project

### 3. Verify Target Membership

After adding files, verify they're in the correct targets:
1. Select any offline image file in Xcode
2. In the File Inspector (right panel), check "Target Membership"
3. Ensure the file is checked for the appropriate target(s)

### 4. Alternative Method: Copy Files Manually

You can also copy image files directly into the filesystem folder:
- `MotiVate/MotiVate/OfflineImages/`

Then add them to the Xcode project and ensure both targets are checked in target membership.

## How It Works

### Network Detection
- The app automatically detects network connectivity
- When internet is unavailable, it switches to offline images
- When network is restored, it switches back to online images

### Fallback Logic
1. **First**: Try to fetch image from Supabase (online)
2. **If network fails**: Automatically switch to bundled offline images
3. **If no offline images**: Display appropriate error message

### Rotation
- Offline images are selected randomly from the available collection
- Each refresh (every 1 minute for widgets) picks a different random image
- Both main app and widget will show offline images when network is unavailable

## Testing Offline Functionality

### Method 1: Disable Network
1. Turn off Wi-Fi and disconnect ethernet
2. Launch the app or check the widget
3. You should see offline images instead of network errors

### Method 2: Airplane Mode (macOS)
1. Enable "Airplane Mode" in System Preferences
2. The app should automatically switch to offline images

### Method 3: Firewall Blocking (Advanced)
1. Use Little Snitch or similar to block the app's network access
2. Test the offline fallback behavior

## Debug Information

The app includes comprehensive logging for offline functionality:

### Console Logs to Look For
- `OfflineImageManager initialized with X offline images`
- `Network unavailable, using offline fallback`
- `Successfully loaded offline image, size: X bytes`
- `No offline images available` (if no images were added)

### Viewing Logs
1. Open Console.app on macOS
2. Filter by "MotiVate" or "MotivationWidgetExtension"
3. Look for offline-related log messages

## Troubleshooting

### "No offline images available"
- Check that images were added to the correct target
- Verify files are in the OfflineImages folders
- Ensure supported file formats (.jpg, .jpeg, .png)

### Images not showing in widget
- Verify images are added to MotivationWidgetExtension target
- Check widget extension logs in Console.app
- Try rebuilding the project

### Images not showing in main app
- Verify images are added to MotiVate target
- Check main app logs in Console.app
- Restart the application

## File Structure

After setup, your project should look like:

```
MotiVate/
└── MotiVate/
    └── OfflineImages/
        ├── README.md
        ├── motivation-image-1.jpg
        ├── courage-quote-2.png
        └── ... (your images)

Note: These same files are accessible by both MotiVate and MotivationWidgetExtension 
targets through shared bundle resources.
```

## Performance Notes

- Offline images are loaded into memory only when needed
- Random selection happens at access time, not startup
- Images are automatically scaled by the UI to fit widget sizes
- Bundle size will increase based on number and size of offline images

## Best Practices

1. **Curate your offline collection**: Choose your best motivational images
2. **Optimize file sizes**: Balance quality vs bundle size
3. **Test thoroughly**: Verify offline functionality works as expected
4. **Keep consistent**: Use similar image styles/themes as your online collection
5. **Update regularly**: Refresh offline images with new content periodically