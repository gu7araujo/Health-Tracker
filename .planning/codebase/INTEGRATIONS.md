# External Integrations

**Analysis Date:** 2026-02-26

## APIs & External Services

**None:**
- No external API integrations detected
- No third-party SDKs present
- Fully self-contained iOS application

## Data Storage

**Databases:**
- None - No traditional database
  - Connection: Not applicable
  - Client: Not applicable

**File Storage:**
- iCloud Drive (primary)
  - Implementation: `HealthTracker/Data/DataSources/ICloudDriveDataSource.swift`
  - Container ID: `iCloud.com.gustavoaraujo.health-tracker`
  - File format: JSON (`HealthTrackerData.json`)
  - Location: iCloud Documents container with local fallback
  - Coordination: Uses `NSFileCoordinator` for safe file access

- Local filesystem (fallback)
  - Implementation: Local Documents directory fallback in `ICloudDriveDataSource.swift`
  - Used when iCloud is unavailable
  - Also supports legacy `UserDefaultsDataSource.swift` (deprecated in favor of iCloud)

**Data Model:**
- JSON-based persistence via `DayDataContainer` model
- Codable protocol for serialization
- Pretty-printed JSON with sorted keys for readability

**Caching:**
- None - Data loaded on-demand from file storage

## Authentication & Identity

**Auth Provider:**
- None (local-only app)
  - Implementation: No authentication layer
  - iCloud access managed by iOS system

**User Management:**
- Single user per device/iCloud account
- No multi-user support

## Monitoring & Observability

**Error Tracking:**
- None - No external error tracking service

**Logs:**
- DEBUG-only console logging
  - `#if DEBUG` conditional print statements
  - File I/O errors logged in `ICloudDriveDataSource` and `UserDefaultsDataSource`
  - JSON decoding errors logged in data sources

## CI/CD & Deployment

**Hosting:**
- iOS App Store (manual deployment via Xcode)
- No automated hosting detected

**CI Pipeline:**
- None - No CI/CD configuration files detected
- No GitHub Actions, fastlane, or other automation detected

**Build Automation:**
- Local build scripts: SwiftLint and SwiftFormat run as Xcode build phases

## Environment Configuration

**Required env vars:**
- None - No environment variables required

**Secrets location:**
- None - No secrets management needed
- iCloud container identifier is public (in `Info.plist`)
- Apple Developer Team ID is non-sensitive (in project settings)

## Webhooks & Callbacks

**Incoming:**
- None - No webhook endpoints

**Outgoing:**
- None - No external webhooks called

## Apple System Integrations

**iCloud:**
- iCloud Drive Documents storage
- Container: `iCloud.com.gustavoaraujo.health-tracker`
- Configured in: `HealthTracker/Info.plist`
- Automatic sync managed by iOS

**System Frameworks:**
- FileManager - iCloud and local file access
- UserDefaults - Legacy storage mechanism (not primary)
- Calendar - Date comparisons and day-based operations

---

*Integration audit: 2026-02-26*
