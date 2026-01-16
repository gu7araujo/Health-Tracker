# Suggested Commands

## Development Commands

### Formatting & Linting
```bash
# Apply SwiftFormat to all files (run after finishing edits)
swiftformat .

# Run SwiftLint to check for issues
swiftlint .
```

### Build & Run
The project is an Xcode project. Use Xcode or `xcodebuild` CLI:
```bash
# Build the project
xcodebuild -project HealthTracker/HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests (if available)
xcodebuild -project HealthTracker/HealthTracker.xcodeproj -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16' test
```

### System Utilities (Darwin/macOS)
```bash
# File operations
ls -la                    # List files with details
find . -name "*.swift"    # Find Swift files
grep -r "pattern" .       # Search in files

# Git operations
git status
git diff
git log --oneline -10

# Open in Xcode
open HealthTracker/HealthTracker.xcodeproj
```

## MCP Tools
- **Serena**: Use for symbolic code navigation, finding references, and understanding codebase structure
- **Context7**: Use for fetching up-to-date Apple framework documentation

## Agent Skills
- **swift-concurrency**: Invoke via `openskills read swift-concurrency` for Swift Concurrency guidance
