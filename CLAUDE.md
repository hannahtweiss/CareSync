# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CareSync is an iOS application built with SwiftUI and SwiftData. The app uses SwiftData for data persistence with a model container configured at the app level.

## Build Commands

Build the project:
```bash
xcodebuild -scheme CareSync -destination 'platform=iOS Simulator,name=iPhone 16 Plus' build
```

Run tests:
```bash
xcodebuild test -scheme CareSync -destination 'platform=iOS Simulator,name=iPhone 16 Plus'
```

Run unit tests only:
```bash
xcodebuild test -scheme CareSync -destination 'platform=iOS Simulator,name=iPhone 16 Plus' -only-testing:CareSyncTests
```

Run UI tests only:
```bash
xcodebuild test -scheme CareSync -destination 'platform=iOS Simulator,name=iPhone 16 Plus' -only-testing:CareSyncUITests
```

## Architecture

### Project Structure
- **Application/**: App entry point and configuration
  - `CareSyncApp.swift`: Main app file with SwiftData ModelContainer setup
- **Presentation/**: SwiftUI views and UI components
- **Data/**: SwiftData models and data layer

### Data Layer
The app uses SwiftData for persistence. The `ModelContainer` is configured in `CareSyncApp.swift` with a schema that includes all `@Model` classes. The container is injected into the SwiftUI environment via `.modelContainer()` modifier, making it available to all views through `@Environment(\.modelContext)`.

Models use the `@Model` macro and should be added to the schema array in `CareSyncApp.swift:14-16` when created.

### UI Layer
Views access the model context via `@Environment(\.modelContext)` and query data using `@Query` property wrapper. The app uses SwiftUI's native navigation components (`NavigationSplitView`).
