# Niblet

A macOS menu bar utility that lets your baby type on the keyboard just like mom and dad.

## How It Works

Niblet blocks all keyboard and mouse input while showing a gentle (optional) color flash for each keypress. Your baby gets to press some keys, you get to keep your computer safe. Type a secret phrase to unlock when playtime's over.

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (the Xcode project is generated, not checked in)
- [SwiftLint](https://github.com/realm/SwiftLint) and [swift-format](https://github.com/swiftlang/swift-format)
- Accessibility permissions (required for input blocking)

```bash
brew install xcodegen swiftlint swift-format
```

## Building

1. Clone the repository
2. Copy `Local.xcconfig.example` to `Local.xcconfig` and set your development team ID
3. Run `xcodegen generate` to create `Niblet.xcodeproj`
4. Open `Niblet.xcodeproj` in Xcode, then build and run

Or from the command line:

```bash
scripts/install.sh   # build Debug and install to /Applications
scripts/dist.sh      # ad-hoc signed Release zip in dist/, for another Mac
```

## Development

Run tests with ⌘U in Xcode, or from the command line:

```bash
# Unit tests
xcodebuild -scheme Niblet -destination 'platform=macOS' test

# Lint (strict)
swift-format lint --strict -r Niblet NibletTests && swiftlint lint --strict

# Auto-fix formatting and lint violations
swift-format format -i -r Niblet NibletTests && swiftlint lint --fix
```

## Usage

1. Click the Niblet icon in the menu bar
2. Click "Lock Input" to start blocking
3. Type your unlock phrase to stop blocking

The app will prompt for accessibility permissions the first time you lock.

## Configuration

Access settings from the menu bar icon:

- **Launch at login**: Start Niblet when you log in
- **Unlock phrase**: The word/phrase to type for unlocking
- **Block function keys**: Whether to block volume, brightness, and media keys
- **Show overlay**: Display unlock hint on screen while locked (required for color flash)

## Forking

If you fork this project, change `bundleIdPrefix` and both `PRODUCT_BUNDLE_IDENTIFIER` values in `project.yml` from `com.nsteinhafel` to your own prefix.

## License

MIT License. See [LICENSE](LICENSE) for details.
