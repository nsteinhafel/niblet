# Niblet

A macOS menu bar utility that lets your baby type on the keyboard just like mom and dad.

## How It Works

Niblet blocks all keyboard and mouse input while showing a gentle (optional) color flash for each keypress. Your baby gets to press some keys, you get to keep your computer safe. Type a secret phrase to unlock when playtime's over.

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ (for building)
- Accessibility permissions (required for input blocking)

## Building

1. Clone the repository
2. Copy `Local.xcconfig.example` to `Local.xcconfig` and set your development team ID
3. Open `Niblet.xcodeproj` in Xcode
4. Build and run

```bash
# Or build from command line
xcodebuild -scheme Niblet -configuration Debug build
```

## Usage

1. Click the Niblet icon in the menu bar
2. Click "Lock Input" to start blocking
3. Type your unlock phrase to stop blocking

The app will prompt for accessibility permissions on first use.

## Configuration

Access settings from the menu bar icon:

- **Unlock phrase**: The word/phrase to type for unlocking
- **Block function keys**: Whether to block volume, brightness, and media keys
- **Show overlay**: Display unlock hint on screen while locked (required for color flash)

## Forking

If you fork this project, update the bundle identifier in the Xcode project settings. The default (`com.nsteinhafel.Niblet`) should be changed to your own identifier.

## License

MIT License. See [LICENSE](LICENSE) for details.
