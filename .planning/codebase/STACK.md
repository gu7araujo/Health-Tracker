# Technology Stack

**Analysis Date:** 2026-02-26

## Languages

**Primary:**
- Swift 6.0 - Main application code
- Swift 5.0 - Test target

**Secondary:**
- None

## Runtime

**Environment:**
- iOS 26.0 (minimum deployment target)
- Xcode 26.0.1+ (project created with 26.0.1)

**Package Manager:**
- Swift Package Manager (SPM) - Native Xcode integration
- No external package.json, Podfile, or Carthage detected
- Lockfile: Not applicable (no third-party dependencies detected)

## Frameworks

**Core:**
- SwiftUI - Primary UI framework for all views
- Foundation - Core Swift functionality
- Charts - Native iOS charting framework for analytics visualizations

**Testing:**
- XCTest - Native iOS unit testing framework
- Test target: `HealthTrackerTests.xctest`

**Build/Dev:**
- Xcode Build System - Native build tooling
- SwiftLint - Code linting (run via build phase script)
- SwiftFormat - Code formatting (run via build phase script, Swift 6 mode)

## Key Dependencies

**Critical:**
- No external third-party dependencies detected

**Infrastructure:**
- Native iOS frameworks only
- SwiftUI Charts (iOS built-in) - Data visualization for analytics views
- Foundation - JSON encoding/decoding, file management, UserDefaults

## Configuration

**Environment:**
- No environment variables required
- No `.env` files present
- iCloud container configured in `Info.plist`: `iCloud.com.gustavoaraujo.health-tracker`

**Build:**
- `HealthTracker.xcodeproj/project.pbxproj` - Xcode project configuration
- `HealthTracker/Info.plist` - App configuration with iCloud entitlements
- Build phase includes SwiftLint and SwiftFormat scripts
- Development region: `pt-BR` (Brazilian Portuguese)
- Localization: String catalogs enabled with symbol generation

## Platform Requirements

**Development:**
- macOS with Xcode 26.0.1 or later
- Apple Developer account for code signing (Team ID: DW48KKFN9M)
- SwiftLint installed via Homebrew (optional but recommended)
- SwiftFormat installed via Homebrew (optional but recommended)

**Production:**
- iOS 26.0 or later
- iPhone and iPad supported (TARGETED_DEVICE_FAMILY = "1,2")
- iCloud Drive enabled for data sync
- App version: 1.2 (build 5)

---

*Stack analysis: 2026-02-26*
