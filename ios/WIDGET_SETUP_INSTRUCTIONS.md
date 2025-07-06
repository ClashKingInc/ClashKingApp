# iOS Widget Setup Instructions

## Adding the WarWidget Extension to Your Xcode Project

### 1. Open Xcode Project
- Open `ios/Runner.xcworkspace` in Xcode

### 2. Add Widget Extension Target
1. In Xcode, go to File → New → Target
2. Choose "Widget Extension" from the templates
3. Configure the extension:
   - Product Name: `WarWidget`
   - Bundle Identifier: `com.clashking.clashkingapp.WarWidget`
   - Language: Swift
   - Include Configuration Intent: No (uncheck this)
   - Click Finish

### 3. Configure App Groups
1. Select the main `Runner` target
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability" and add "App Groups"
4. Add a new app group: `group.com.clashking.clashkingapp`

5. Select the `WarWidget` target
6. Go to "Signing & Capabilities" tab
7. Click "+ Capability" and add "App Groups"
8. Add the same app group: `group.com.clashking.clashkingapp`

### 4. Replace Generated Widget Files
1. Delete the generated widget files in the WarWidget folder
2. Copy the Swift files from this project:
   - `WarWidget.swift`
   - `WarWidgetProvider.swift`
   - `WarWidgetEntry.swift`
   - `WarWidgetEntryView.swift`
   - `WarWidgetBundle.swift`

### 5. Update Widget Info.plist
Replace the generated `Info.plist` in the WarWidget folder with the one provided.

### 6. Configure Bundle Identifiers
Make sure the bundle identifiers are set correctly:
- Main app: `com.clashking.clashkingapp`
- Widget extension: `com.clashking.clashkingapp.WarWidget`

### 7. Update iOS Deployment Target
Set the deployment target for both the main app and widget extension to iOS 14.0 or later (required for WidgetKit).

### 8. Build and Test
1. Build the project (Cmd+B)
2. Run on a device or simulator
3. Add the widget to the home screen:
   - Long press on home screen
   - Tap the "+" button
   - Search for "ClashKing War"
   - Add the widget

## Widget Features

### Small Widget
- Shows war status with colored header
- Displays primary text (time remaining, score, etc.)
- Shows last update time

### Medium Widget
- Shows war status with colored header
- Displays clan vs opponent with badges
- Shows destruction percentages and attack counts
- Real-time war progress

### Data Updates
- Widget refreshes every 15 minutes automatically
- Data is shared between the main app and widget via App Groups
- Widget shows cached data when offline

## Troubleshooting

### Widget Not Updating
1. Check that App Groups are configured correctly on both targets
2. Ensure the group identifier matches: `group.com.clashking.clashkingapp`
3. Verify that the main app is saving data to UserDefaults with the correct suite name

### Build Errors
1. Make sure iOS deployment target is 14.0+ for both targets
2. Check that all Swift files are added to the WarWidget target
3. Verify bundle identifiers are correct

### Widget Not Appearing
1. Ensure the widget extension is being built with the main app
2. Check that the widget target is included in the scheme
3. Try deleting and re-adding the widget on the home screen