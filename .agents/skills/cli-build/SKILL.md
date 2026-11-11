---
name: cli-build
description: Build the HealthTracker app or compile the test target from the command line with xcodebuild. Use only after an Xcode MCP build call returned an error you can quote, before the first xcodebuild build of a session. Not for workflow subagents or gates, which use scripts/quality.
---

# Build HealthTracker from the CLI

The fallback for a main session whose Xcode MCP `BuildProject` returned an error: quote that error to the user first (root `AGENTS.md`, Building and Validating). A device or preview tool's error is no reason to fall back, and a disconnected MCP means asking the user to run `/mcp`. Pipe every command through `xcbeautify` for readable output.

Build the app:
```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -configuration Debug build | xcbeautify
```

Compile the tests without running them (faster; use to check test code compiles):
```bash
xcodebuild build-for-testing -project HealthTracker.xcodeproj -scheme HealthTracker | xcbeautify
```

**Done when:** the command ends in `Build Succeeded`. A failure prints the offending file and line — fix and rebuild until green.
